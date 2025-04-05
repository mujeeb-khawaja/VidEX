import cv2
from PIL import Image
import numpy as np
from models.model import model, preprocess, device
import logging
import torch
from sklearn.metrics.pairwise import cosine_similarity
from database.database import collection


__all__ = ['collection']


def process_frame(frame):
    # ye aik helper function hai to preprocess a frame for CLIP (model)
    try:
        # convert frame to RGB and preprocess for CLIP bcs CV2 used BGR
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        pil_image = Image.fromarray(frame)
        pil_image = pil_image.resize((224, 224), Image.Resampling.LANCZOS)
        return pil_image
    except Exception as e:
        logging.error(f"Error processing frame: {e}")
        return None


def pad_or_truncate_frames(frames, target_count=8):
    # this ensures the frame list is exactly `target_count` frames long
    if len(frames) > target_count:
        return frames[:target_count]
    while len(frames) < target_count:
        frames.append(frames[-1])
    return frames


def generate_embeddings(frames, target_count=8):
    # generate embeddings for the given frames using the CLIP model
    try:
        frames = pad_or_truncate_frames(frames, target_count)

        inputs = torch.stack([preprocess(frame) for frame in frames]).to(device)

        with torch.no_grad():
            # Generate embeddings using CLIP's image encoder
            image_features = model.encode_image(inputs)

        # normalizinggg the embeddings for comparison
        return image_features.cpu().numpy().tolist()
    except Exception as e:
        logging.error(f"Error generating embeddings: {e}")
        return None


logging.basicConfig(level=logging.INFO)


def display_clip_details(clip_path, threshold=0.55):
    try:
        logging.info(f"Processing clip for retrieval: {clip_path}")
        cap = cv2.VideoCapture(clip_path)
        if not cap.isOpened():
            logging.error(f"Error: Could not open video file at {clip_path}")
            return

        all_frames = []
        frame_count = 0

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            if frame_count % 100 == 0:
                frame_resized = process_frame(frame)
                if frame_resized:
                    all_frames.append(frame_resized)

            frame_count += 1

        cap.release()

        if not all_frames:
            logging.error("No frames were processed. Check the video file.")
            return

        clip_embeddings = generate_embeddings(all_frames, target_count=8)  # Fixed frame count
        if clip_embeddings is None:
            logging.error("Error generating clip embeddings.")
            return

        logging.info(f"Clip Embeddings: {clip_embeddings}")

        clip_embeddings = np.array(clip_embeddings).flatten()

        movies = list(collection.find({}, {"_id": 0, "movie_name": 1, "genre": 1, "release_year": 1, "embeddings": 1}))
        if not movies:
            logging.error("No movies found in the database.")
            return

        database_embeddings = []
        movie_info = []

        for movie in movies:
            movie_embedding = np.array(movie["embeddings"]).flatten()
            database_embeddings.append(movie_embedding)
            movie_info.append((movie["movie_name"], movie["genre"], movie["release_year"]))

        if not database_embeddings:
            logging.error("No embeddings found in the database.")
            return

        similarities = cosine_similarity([clip_embeddings], database_embeddings)

        # Get the highest similarity score
        max_similarity = similarities[0].max()
        matched_index = similarities[0].argmax()

        logging.info(f"Max Similarity: {max_similarity}")

        # ab check kro if the similarity exceeds the threshold
        if max_similarity >= threshold:
            matched_movie = movie_info[matched_index]

            # 1) Build the result dict
            result = {
                "movie_name": matched_movie[0],
                "genre": matched_movie[1],
                "release_year": matched_movie[2],
                "similarity": float(max_similarity),
            }
            # 2) Print to console
            print("\nMovie Details:")
            print(f"Name: {matched_movie[0]}")
            print(f"Genre: {matched_movie[1]}")
            print(f"Release Year: {matched_movie[2]}")
            # 3) Return the dict
            return result
        else:
            logging.info("No match found.")
    except Exception as e:
        logging.error(f"Error retrieving movie details: {e}")

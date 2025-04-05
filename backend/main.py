from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware  # Import CORS middleware
from generation import display_clip_details

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods
    allow_headers=["*"],  # Allows all headers
)

@app.post("/match_clip/")
async def match_clip(file: UploadFile = File(...)):
    try:
        clip_path = f"temp_{file.filename}"
        with open(clip_path, "wb") as f:
            content = await file.read()
            f.write(content)

        result = display_clip_details(clip_path)
        
        if result:
            return {"status": "success", "message": "Match found!", "data": result}
        else:
            return {"status": "error", "message": "No match found."}
    
    except Exception as e:
        return {"status": "error", "message": f"Processing failed. {e}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
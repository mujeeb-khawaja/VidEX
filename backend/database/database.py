from pymongo import MongoClient
from pymongo.server_api import ServerApi

uri = "mongodb+srv://khansarim388:sarimlintamujeeb@videx.jli34ly.mongodb.net/?retryWrites=true&w=majority&appName=Videx"

client = MongoClient(
    uri,
    server_api=ServerApi('1'),
    tls=True,
    tlsAllowInvalidCertificates=True  # For development only!
)

db = client['videx']
collection = db['movie_details']

def test_connection():
    try:
        client.admin.command('ping')
        print("Connected to MongoDB Atlas!")
    except Exception as e:
        print(f"MongoDB Connection Error: {e}")
from fastapi import FastAPI
from message import *

app = FastAPI()

@app.get("/api/hello")
async def read_hello():
    return "Hello!"

@app.get("/api/thanks")
async def thanks():
    return message

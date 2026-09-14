from fastapi import FastAPI

app = FastAPI(
    title="Rahul AI Chatbot",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "message": "Rahul AI Chatbot is running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "version": "1.0.0"
    }


@app.post("/chat")
def chat(question: str):
    return {
        "question": question,
        "answer": f"You asked: {question}"
    }
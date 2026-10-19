import { useState, useRef, useEffect } from "react";
import { useChat } from "./hooks/useChat";
import "./App.css";

const USER_ID = localStorage.getItem("userId") || crypto.randomUUID();
localStorage.setItem("userId", USER_ID);

const SESSION_ID =
  new URLSearchParams(window.location.search).get("session") ||
  localStorage.getItem("sessionId") ||
  crypto.randomUUID();
localStorage.setItem("sessionId", SESSION_ID);

function App() {
  const { messages, sendMessage, streaming, error } = useChat(
    USER_ID,
    SESSION_ID
  );
  const [input, setInput] = useState("");
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSubmit = (e) => {
    e.preventDefault();
    const trimmed = input.trim();
    if (!trimmed) return;
    sendMessage(trimmed);
    setInput("");
  };

  return (
    <div className="chat-container">
      <header className="chat-header">
        <h1>ElixirLLM</h1>
        <span className="model-badge">Gemini 2.5 Flash</span>
      </header>

      <div className="messages">
        {messages.length === 0 && (
          <div className="empty-state">Send a message to start chatting.</div>
        )}
        {messages.map((msg, i) => (
          <div key={i} className={`message ${msg.role}`}>
            <div className="message-role">
              {msg.role === "user" ? "You" : "AI"}
            </div>
            <div className="message-content">
              {msg.content}
              {msg.streaming && <span className="cursor">|</span>}
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {error && <div className="error-banner">{error}</div>}

      <form className="input-bar" onSubmit={handleSubmit}>
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type a message..."
          disabled={streaming}
          autoFocus
        />
        <button type="submit" disabled={streaming || !input.trim()}>
          {streaming ? "..." : "Send"}
        </button>
      </form>
    </div>
  );
}

export default App;

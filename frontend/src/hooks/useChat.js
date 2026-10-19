import { useState, useEffect, useRef, useCallback } from "react";
import { connectSocket, joinChat } from "../socket";

export function useChat(userId, sessionId) {
  const [messages, setMessages] = useState([]);
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState(null);
  const channelRef = useRef(null);
  const streamBufferRef = useRef("");

  useEffect(() => {
    const socket = connectSocket(userId);

    joinChat(socket, sessionId).then(({ channel, history }) => {
      channelRef.current = channel;

      // Load persisted history
      if (history.length > 0) {
        setMessages(history.map((m) => ({ role: m.role, content: m.content })));
      }

      channel.on("ai_chunk", ({ text }) => {
        streamBufferRef.current += text;
        setMessages((prev) => {
          const updated = [...prev];
          const last = updated[updated.length - 1];
          if (last && last.role === "assistant" && last.streaming) {
            updated[updated.length - 1] = {
              ...last,
              content: streamBufferRef.current,
            };
          }
          return updated;
        });
      });

      channel.on("ai_done", ({ text }) => {
        streamBufferRef.current = "";
        setStreaming(false);
        setMessages((prev) => {
          const updated = [...prev];
          const last = updated[updated.length - 1];
          if (last && last.role === "assistant") {
            updated[updated.length - 1] = {
              role: "assistant",
              content: text,
              streaming: false,
            };
          }
          return updated;
        });
      });

      channel.on("ai_error", ({ reason }) => {
        setStreaming(false);
        setError(reason);
      });
    });

    return () => {
      channelRef.current?.leave();
      socket.disconnect();
    };
  }, [userId, sessionId]);

  const sendMessage = useCallback(
    (content) => {
      if (!channelRef.current || streaming) return;

      setError(null);
      setStreaming(true);
      streamBufferRef.current = "";

      setMessages((prev) => [
        ...prev,
        { role: "user", content },
        { role: "assistant", content: "", streaming: true },
      ]);

      channelRef.current.push("new_message", { content });
    },
    [streaming]
  );

  return { messages, sendMessage, streaming, error };
}

import { Socket } from "phoenix";

// Same domain: derive ws/wss from current page protocol
const wsProtocol = window.location.protocol === "https:" ? "wss:" : "ws:";
const SOCKET_URL =
  import.meta.env.VITE_WS_URL || `${wsProtocol}//${window.location.host}/socket`;

export function connectSocket(userId) {
  const socket = new Socket(SOCKET_URL, {
    params: { token: userId },
  });

  socket.connect();
  return socket;
}

export function joinChat(socket, sessionId) {
  const channel = socket.channel(`chat:${sessionId}`, {});

  return new Promise((resolve, reject) => {
    channel
      .join()
      .receive("ok", (resp) => resolve({ channel, history: resp.history || [] }))
      .receive("error", (resp) => reject(resp));
  });
}

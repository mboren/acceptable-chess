import { Elm } from "../src/Main.elm";
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})
socket.connect()
let chatInput         = document.querySelector("#chat-input")
let messagesContainer = document.querySelector("#messages")


// Now that you are connected, you can join channels with a topic:
let gameId = document.querySelector("#game-id").dataset.gameId;
let playerId = document.querySelector("#game-id").dataset.playerId;
let channel = socket.channel("room:" + gameId, {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

chatInput.addEventListener("keypress", event => {
  if(event.key === 'Enter'){
    channel.push("new_msg", {body: chatInput.value})
    chatInput.value = ""
  }
})


var app = Elm.Main.init({
  node: document.getElementById('elm-main'),

});

channel.on("new_msg", payload => {
  let messageItem = document.createElement("p")
  messageItem.innerText = `[${Date()}] ${payload.body}`
  messagesContainer.appendChild(messageItem)
  app.ports.messageReceiver.send(payload.body)
})
channel.on("game_state", payload => {
    console.log("phx_reply", payload)
  app.ports.messageReceiver.send(payload.body)
})

app.ports.sendMessage.subscribe(function (message) {
    console.log("message from elm: ", message)
    if(message === "ready") {
        console.log("got ready from elm")
        channel.push("ready", {game_id: gameId, player_id: playerId})
    } else {
        channel.push("move", {game_id: gameId, player_id: playerId, move: message})
    }
})

app.ports.sendMove.subscribe(function (message) {
    console.log("move from elm: ", message)
    channel.push("move", {game_id: gameId, player_id: playerId, move: message})
})

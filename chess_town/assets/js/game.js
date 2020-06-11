import { Elm } from "../src/Main.elm";
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})
socket.connect()

let gameId = document.querySelector("#game-id").dataset.gameId;
let playerId = document.querySelector("#game-id").dataset.playerId;
let channel = socket.channel("room:" + gameId + ":" + playerId, {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })


var app = Elm.Main.init({
  node: document.getElementById('elm-main'),
  flags: {innerWidth: window.innerWidth, innerHeight: window.innerHeight},
});

channel.on("game_state", payload => {
    console.log("phx_reply", payload)
  app.ports.messageReceiver.send(payload.body)
})

app.ports.sendMessage.subscribe(function (message) {
    console.log("message from elm: ", message)
    channel.push(message, {game_id: gameId, player_id: playerId})
})

app.ports.sendMove.subscribe(function (message) {
    console.log("move from elm: ", message)
    channel.push("move", {game_id: gameId, player_id: playerId, move: message})
})

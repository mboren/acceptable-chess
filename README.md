# Acceptable chess

Online chess game client/server. Playable, but still definitely WIP.
Try it out [here](https://www.borentobewild.com/chess)
![chess](readme-images/side-by-side-opening-short.gif)

# Technology
Frontend is written in [Elm](https://elm-lang.org/).

Backend is written in [Elixir](https://elixir-lang.org/) using the [Phoenix web framework](https://phoenixframework.org/)

A lot of the game communciation is done with websockets. I used Phoenix channels to manage the connections.

I used the erlang library [binbo](https://github.com/DOBRO/binbo) for most of the chess logic.

I used [mdgriffith/elm-ui](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/) for the user interface.

# About
This is my first elixir project.
I'm fairly certain that the backend isn't structured very idiomatically for elixir. 

it has cool features like:
- refresh the game whenever you want with no consequences
- works on my phone, might work on yours
- no user accounts
- play with your friends
- no chat, so nobody can tell me how bad at chess I am

## Dependencies
- Elixir 1.10.2
- Erlang 22.3
- Elm 0.19.1

## Installation
All code blocks are to be run in a shell starting at the project root.

Install Elixir, Erlang, and Elm however you like, then:
```shell script
mix deps.get
cd assets/
npm install
elm install
```

## Running the project
```shell script
mix phx.server
```
- Open `localhost:4000/chess` in your browser.
- Click "new game"
- Copy the invite link and open in an incognito window/other browser.

## Running tests
### Elixir tests
```shell script
mix test
```

### dialyzer (Erlang/Elixir static type checker)
First run will be incredibly slow (like, 3-10 minutes)
```shell script
mix dialyzer
```

### Elm tests
```shell script
cd assets/
elm-test
```

## Attribution
Chess piece SVGs are from wikimedia user [Colin Burnett](https://en.wikipedia.org/wiki/User:Cburnett)

They released them under the following licenses: GFDL, BSD, GPL

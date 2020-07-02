module History exposing (..)


type alias History ply =
    { pastMoves : List ( ply, ply )
    , incompleteMove : Maybe ply
    }


empty =
    { pastMoves = [], incompleteMove = Nothing }


moveNumber : History a -> Int
moveNumber history =
    1 + List.length history.pastMoves


render : (a -> b) -> (Int -> b) -> History a -> List b
render renderPly renderNumber history =
    let
        renderedPastMoves : List b
        renderedPastMoves =
            history.pastMoves
                |> List.reverse
                |> List.indexedMap (\i ( w, b ) -> [ renderNumber (i + 1), renderPly w, renderPly b ])
                |> List.concat
    in
    case history.incompleteMove of
        Nothing ->
            renderedPastMoves

        Just ply ->
            renderedPastMoves ++ [ renderNumber (1 + List.length history.pastMoves), renderPly ply ]


add : a -> History a -> History a
add ply history =
    case history.incompleteMove of
        Nothing ->
            { history | incompleteMove = Just ply }

        Just p ->
            { history | pastMoves = ( p, ply ) :: history.pastMoves, incompleteMove = Nothing }


fromList : List a -> History a
fromList list =
    List.foldl add empty list


getLastPly : History a -> Maybe a
getLastPly history =
    case history.incompleteMove of
        Just p ->
            Just p

        Nothing ->
            case history.pastMoves of
                [] ->
                    Nothing

                ( w, b ) :: _ ->
                    Just b


toList : History a -> List a
toList history =
    case history.incompleteMove of
        Nothing ->
            List.concatMap (\( w, b ) -> [ w, b ]) (List.reverse history.pastMoves)

        Just pl ->
            List.concatMap (\( w, b ) -> [ w, b ]) (List.reverse history.pastMoves) ++ [ pl ]

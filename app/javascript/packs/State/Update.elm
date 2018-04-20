module State.Update exposing (update)

import Category
import Cluster
import Component
import Http
import Issue
import Json.Decode as D
import Msg exposing (..)
import Navigation
import Rails
import SelectList exposing (Position(..), SelectList)
import Service
import State exposing (State)
import Tier
import Utils


update : Msg -> State -> Maybe ( State, Cmd Msg )
update msg state =
    case msg of
        ChangeSelectedCluster id ->
            stringToId Cluster.Id id
                |> Maybe.map (handleChangeSelectedCluster state)

        ChangeSelectedCategory id ->
            stringToId Category.Id id
                |> Maybe.map (handleChangeSelectedCategory state)

        ChangeSelectedIssue id ->
            stringToId Issue.Id id
                |> Maybe.map (handleChangeSelectedIssue state)

        ChangeSelectedTier id ->
            stringToId Tier.Id id
                |> Maybe.map (handleChangeSelectedTier state)

        ChangeSelectedComponent id ->
            stringToId Component.Id id
                |> Maybe.map (handleChangeSelectedComponent state)

        ChangeSelectedService id ->
            stringToId Service.Id id
                |> Maybe.map (handleChangeSelectedService state)

        ChangeSubject subject ->
            Just <| handleChangeSubject state subject ! []

        ChangeTierField index value ->
            Just <| handleChangeTierField state index value ! []

        StartSubmit ->
            Just
                ( { state | isSubmitting = True }
                , submitForm state
                )

        SubmitResponse result ->
            case result of
                Ok () ->
                    -- Success response indicates case was successfully
                    -- created, so redirect to root page.
                    Just ( state, Navigation.load "/" )

                Err error ->
                    Just <|
                        { state
                            | error = Just (formatSubmitError error)
                            , isSubmitting = False
                        }
                            ! []

        ClearError ->
            Just <| { state | error = Nothing } ! []

        ClusterChargingInfoModal modalState ->
            Just ({ state | clusterChargingInfoModal = modalState } ! [])

        ChargeablePreSubmissionModal modalState ->
            Just ({ state | chargeablePreSubmissionModal = modalState } ! [])


stringToId : (Int -> id) -> String -> Maybe id
stringToId constructor idString =
    String.toInt idString
        |> Result.toMaybe
        |> Maybe.map constructor


handleChangeSelectedCluster : State -> Cluster.Id -> ( State, Cmd Msg )
handleChangeSelectedCluster state clusterId =
    let
        newClusters =
            SelectList.select (Utils.sameId clusterId) state.clusters
    in
    { state | clusters = newClusters } ! []


handleChangeSelectedCategory : State -> Category.Id -> ( State, Cmd Msg )
handleChangeSelectedCategory state categoryId =
    { state
        | clusters =
            Cluster.setSelectedCategory state.clusters categoryId
    }
        ! []


handleChangeSelectedIssue : State -> Issue.Id -> ( State, Cmd Msg )
handleChangeSelectedIssue state issueId =
    { state
        | clusters =
            Cluster.setSelectedIssue state.clusters issueId
    }
        ! []


handleChangeSelectedTier : State -> Tier.Id -> ( State, Cmd Msg )
handleChangeSelectedTier state tierId =
    { state
        | clusters =
            Cluster.setSelectedTier state.clusters tierId
    }
        ! []


handleChangeSelectedComponent : State -> Component.Id -> ( State, Cmd Msg )
handleChangeSelectedComponent state componentId =
    { state
        | clusters =
            Cluster.setSelectedComponent state.clusters componentId
    }
        ! []


handleChangeSelectedService : State -> Service.Id -> ( State, Cmd Msg )
handleChangeSelectedService state serviceId =
    { state
        | clusters =
            Cluster.setSelectedService state.clusters serviceId
    }
        ! []


handleChangeSubject : State -> String -> State
handleChangeSubject state subject =
    { state
        | clusters =
            Cluster.updateSelectedIssue state.clusters (Issue.setSubject subject)
    }


handleChangeTierField : State -> Int -> String -> State
handleChangeTierField state index value =
    { state
        | clusters =
            Cluster.updateSelectedIssue state.clusters
                (Issue.updateSelectedTierField index value)
    }


submitForm : State -> Cmd Msg
submitForm state =
    let
        body =
            State.encoder state |> Http.jsonBody

        getErrors =
            D.field "errors" D.string
                |> Rails.decodeErrors
    in
    Rails.post "/cases" body (D.succeed ())
        |> Http.send (getErrors >> SubmitResponse)


formatSubmitError : Rails.Error String -> String
formatSubmitError error =
    case error.rails of
        Just errors ->
            errors

        Nothing ->
            formatHttpError error.http


formatHttpError : Http.Error -> String
formatHttpError error =
    case error of
        Http.BadUrl url ->
            "invalid URL: " ++ url

        Http.Timeout ->
            "request timed out"

        Http.NetworkError ->
            "unable to access network"

        Http.BadStatus { status } ->
            "unexpected response status: " ++ toString status.code

        Http.BadPayload message { status } ->
            "bad payload: " ++ message ++ "; status: " ++ toString status.code

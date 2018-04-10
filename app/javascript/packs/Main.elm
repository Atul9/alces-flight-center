module Main exposing (..)

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Category
import Cluster exposing (Cluster)
import Component exposing (Component)
import FieldValidation exposing (FieldValidation(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Http
import Issue exposing (Issue)
import Issues
import Json.Decode as D
import Maybe.Extra
import Navigation
import Rails
import SelectList exposing (Position(..), SelectList)
import SelectList.Extra
import Service exposing (Service)
import State exposing (State)
import Utils
import Validation
import View.Fields as Fields
import View.PartsField as PartsField exposing (PartsFieldConfig(..))


-- MODEL


type Model
    = Initialized State
    | Error String


decodeInitialModel : D.Value -> Model
decodeInitialModel value =
    let
        result =
            D.decodeValue State.decoder value
    in
    case result of
        Ok state ->
            Initialized state

        Err message ->
            Error message



-- INIT


init : D.Value -> ( Model, Cmd Msg )
init flags =
    ( decodeInitialModel flags, Cmd.none )



-- VIEW
-- XXX Refactor functions in here and in `View.*` modules to use
-- `elm-bootstrap`.


view : Model -> Html Msg
view model =
    case model of
        Initialized state ->
            let
                validatedState =
                    Validation.validateState state

                logDefinition =
                    Debug.log "validatedState" validatedState
            in
            div []
                (Maybe.Extra.values
                    [ chargingInfoModal state |> Just
                    , chargeableIssuePreSubmissionModal state |> Just
                    , State.selectedIssue state |> chargeableIssueAlert
                    , submitErrorAlert state
                    , caseForm state |> Just
                    ]
                )

        Error message ->
            span []
                [ text
                    ("Error initializing form: "
                        ++ message
                        ++ ". Please contact "
                    )
                , supportEmailLink
                , text "."
                ]


supportEmailLink : Html msg
supportEmailLink =
    let
        email =
            "support@alces-software.com"
    in
    a
        [ "mailto:" ++ email |> href
        , target "_blank"
        ]
        [ text email ]


chargingInfoModal : State -> Html Msg
chargingInfoModal state =
    let
        cluster =
            SelectList.selected state.clusters

        chargingInfo =
            cluster.chargingInfo
                |> Maybe.map text
                |> Maybe.withDefault noChargingInfoAvailable

        noChargingInfoAvailable =
            span []
                [ text "No charging info has been provided by Alces Software for "
                , strong [] [ text cluster.name ]
                , text "; if you require clarification on what charges you may incur please contact "
                , supportEmailLink
                , text "."
                ]
    in
    Modal.config ClusterChargingInfoModal
        |> Modal.h5 [] [ cluster.name ++ " charging info" |> text ]
        |> Modal.body [] [ chargingInfo ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs
                    [ ClusterChargingInfoModal Modal.hiddenState |> onClick ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view state.clusterChargingInfoModal


chargeableIssuePreSubmissionModal : State -> Html Msg
chargeableIssuePreSubmissionModal state =
    let
        bodyContent =
            [ p []
                [ text "The selected issue ("
                , em [] [ State.selectedIssue state |> Issue.name |> text ]
                , text ") is chargeable, and creating this support case may incur a support credit charge."
                ]
            , p [] [ text "Do you wish to continue?" ]
            ]
    in
    Modal.config ChargeableIssuePreSubmissionModal
        |> Modal.h5 [] [ text "This support case may incur charges" ]
        |> Modal.body [] bodyContent
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs
                    [ ChargeableIssuePreSubmissionModal Modal.hiddenState |> onClick ]
                ]
                [ text "Cancel" ]
            , Button.button
                [ Button.outlineWarning
                , Button.attrs
                    [ onClick StartSubmit ]
                ]
                [ text "Create Case" ]
            ]
        |> Modal.view state.chargeableIssuePreSubmissionModal


submitErrorAlert : State -> Maybe (Html Msg)
submitErrorAlert state =
    -- This closely matches the error alert we show from Rails, but is managed
    -- by Elm rather than Bootstrap JS.
    let
        displayError =
            \error ->
                Alert.danger
                    [ button
                        [ type_ "button"
                        , class "close"
                        , attribute "aria-label" "Dismiss"
                        , onClick ClearError
                        ]
                        [ span [ attribute "aria-hidden" "true" ] [ text "×" ] ]
                    , text ("Error creating support case: " ++ error ++ ".")
                    ]
    in
    Maybe.map displayError state.error


chargeableIssueAlert : Issue -> Maybe (Html Msg)
chargeableIssueAlert issue =
    let
        dollar =
            span [ class "fa fa-dollar" ] []

        chargingInfo =
            " This issue is chargeable and may incur a charge of support credits. "

        clusterChargingInfoLinkText =
            "Click here for the charging details for this cluster."
    in
    if Issue.isChargeable issue then
        Alert.warning
            [ dollar
            , dollar
            , dollar
            , text chargingInfo
            , Alert.link
                [ ClusterChargingInfoModal Modal.visibleState |> onClick

                -- This makes this display as a normal link, but clicking on it
                -- not reload the page. There may be a better way to do this;
                -- `href="#"` does not work.
                , href "javascript:void(0)"
                ]
                [ text clusterChargingInfoLinkText ]
            ]
            |> Just
    else
        Nothing


caseForm : State -> Html Msg
caseForm state =
    let
        submitMsg =
            if State.selectedIssue state |> Issue.isChargeable then
                ChargeableIssuePreSubmissionModal Modal.visibleState
            else
                StartSubmit

        formElements =
            Maybe.Extra.values
                [ maybeClustersField state
                , maybeServicesField state
                , maybeCategoriesField state
                , issuesField state |> Just
                , maybeComponentsField state
                , subjectField state |> Just
                , detailsField state |> Just
                , submitButton state |> Just
                ]
    in
    Html.form [ onSubmit submitMsg ] formElements


maybeClustersField : State -> Maybe (Html Msg)
maybeClustersField state =
    let
        clusters =
            state.clusters

        singleCluster =
            SelectList.toList clusters
                |> List.length
                |> (==) 1
    in
    if singleCluster then
        -- Only one Cluster available => no need to display Cluster selection
        -- field.
        Nothing
    else
        Just
            (Fields.selectField Validation.Cluster
                clusters
                Cluster.extractId
                .name
                (always Valid)
                ChangeSelectedCluster
                state
            )


maybeCategoriesField : State -> Maybe (Html Msg)
maybeCategoriesField state =
    State.selectedService state
        |> .issues
        |> Issues.categories
        |> Maybe.map
            (\categories_ ->
                Fields.selectField Validation.Category
                    categories_
                    Category.extractId
                    .name
                    (always Valid)
                    ChangeSelectedCategory
                    state
            )


issuesField : State -> Html Msg
issuesField state =
    let
        selectedServiceAvailableIssues =
            State.selectedServiceAvailableIssues state

        validateIssue =
            FieldValidation.validateWithError
                """This cluster is self-managed; you may only request
                consultancy support from Alces Software."""
                (State.issueAvailableForSelectedCluster state)
    in
    Fields.selectField Validation.Issue
        selectedServiceAvailableIssues
        Issue.extractId
        Issue.name
        validateIssue
        ChangeSelectedIssue
        state


maybeComponentsField : State -> Maybe (Html Msg)
maybeComponentsField state =
    let
        config =
            if State.selectedIssue state |> Issue.requiresComponent |> not then
                NotRequired
            else if state.singleComponent then
                SinglePartField (State.selectedComponent state)
            else
                SelectionField .components
    in
    PartsField.maybePartsField Validation.Component
        config
        Component.extractId
        Issue.requiresComponent
        state
        ChangeSelectedComponent


maybeServicesField : State -> Maybe (Html Msg)
maybeServicesField state =
    let
        config =
            if state.singleComponent && singleServiceApplicable then
                -- No need to allow selection of a Service if we're in single
                -- Component mode and there's only one Service with Issues
                -- which require a Component.
                NotRequired
            else if state.singleService then
                SinglePartField (State.selectedService state)
            else
                SelectionField .services

        singleServiceApplicable =
            SelectList.toList state.clusters
                |> List.length
                |> (==) 1
    in
    PartsField.maybePartsField Validation.Service
        config
        Service.extractId
        (always True)
        state
        ChangeSelectedService


subjectField : State -> Html Msg
subjectField state =
    let
        selectedIssue =
            State.selectedIssue state

        validateSubject =
            FieldValidation.validateWithEmptyError Issue.subjectValid
    in
    Fields.inputField Validation.Subject
        selectedIssue
        Issue.subject
        validateSubject
        ChangeSubject
        state


detailsField : State -> Html Msg
detailsField state =
    let
        selectedIssue =
            State.selectedIssue state

        validateDetails =
            FieldValidation.validateWithEmptyError Issue.detailsValid
    in
    Fields.textareaField Validation.Details
        selectedIssue
        Issue.details
        validateDetails
        ChangeDetails
        state


submitButton : State -> Html Msg
submitButton state =
    input
        [ type_ "submit"
        , value "Create Case"
        , class "btn btn-primary btn-block"
        , disabled (state.isSubmitting || Validation.invalidState state)
        ]
        []



-- MESSAGE


type Msg
    = ChangeSelectedCluster String
    | ChangeSelectedCategory String
    | ChangeSelectedIssue String
    | ChangeSelectedComponent String
    | ChangeSelectedService String
    | ChangeSubject String
    | ChangeDetails String
    | StartSubmit
    | SubmitResponse (Result (Rails.Error String) ())
    | ClearError
    | ClusterChargingInfoModal Modal.State
    | ChargeableIssuePreSubmissionModal Modal.State



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Initialized state ->
            let
                ( newState, cmd ) =
                    updateState msg state
                        |> Maybe.withDefault ( state, Cmd.none )
            in
            ( Initialized newState, cmd )

        Error message ->
            model ! []


updateState : Msg -> State -> Maybe ( State, Cmd Msg )
updateState msg state =
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

        ChangeSelectedComponent id ->
            stringToId Component.Id id
                |> Maybe.map (handleChangeSelectedComponent state)

        ChangeSelectedService id ->
            stringToId Service.Id id
                |> Maybe.map (handleChangeSelectedService state)

        ChangeSubject subject ->
            Just
                ( handleChangeSubject state subject, Cmd.none )

        ChangeDetails details ->
            Just
                ( handleChangeDetails state details, Cmd.none )

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
                    Just
                        ( { state
                            | error = Just (formatSubmitError error)
                            , isSubmitting = False
                          }
                        , Cmd.none
                        )

        ClearError ->
            Just ( { state | error = Nothing }, Cmd.none )

        ClusterChargingInfoModal modalState ->
            Just ({ state | clusterChargingInfoModal = modalState } ! [])

        ChargeableIssuePreSubmissionModal modalState ->
            Just ({ state | chargeableIssuePreSubmissionModal = modalState } ! [])


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
    ( { state | clusters = newClusters }
    , Cmd.none
    )


handleChangeSelectedCategory : State -> Category.Id -> ( State, Cmd Msg )
handleChangeSelectedCategory state categoryId =
    ( { state
        | clusters =
            Cluster.setSelectedServiceSelectedCategory state.clusters categoryId
      }
    , Cmd.none
    )


handleChangeSelectedIssue : State -> Issue.Id -> ( State, Cmd Msg )
handleChangeSelectedIssue state issueId =
    ( { state
        | clusters =
            Cluster.setSelectedServiceSelectedIssue state.clusters issueId
      }
    , Cmd.none
    )


handleChangeSelectedComponent : State -> Component.Id -> ( State, Cmd Msg )
handleChangeSelectedComponent state componentId =
    ( { state
        | clusters =
            Cluster.setSelectedComponent state.clusters componentId
      }
    , Cmd.none
    )


handleChangeSelectedService : State -> Service.Id -> ( State, Cmd Msg )
handleChangeSelectedService state serviceId =
    ( { state
        | clusters =
            Cluster.setSelectedService state.clusters serviceId
      }
    , Cmd.none
    )


handleChangeSubject : State -> String -> State
handleChangeSubject state subject =
    let
        newClusters =
            SelectList.Extra.mapSelected updateCluster state.clusters

        updateCluster =
            \cluster ->
                SelectList.Extra.mapSelected updateService cluster.services
                    |> Cluster.asServicesIn cluster

        updateService =
            \service ->
                updateIssues service.issues
                    |> Service.asIssuesIn service

        updateIssues =
            Issues.mapIssue updateIssueSubject

        updateCategory =
            \category ->
                SelectList.Extra.mapSelected updateIssueSubject category.issues
                    |> Category.asIssuesIn category

        updateIssueSubject =
            Issue.setSubject subject
    in
    { state | clusters = newClusters }


handleChangeDetails : State -> String -> State
handleChangeDetails state details =
    let
        newClusters =
            SelectList.Extra.mapSelected updateCluster state.clusters

        updateCluster =
            \cluster ->
                SelectList.Extra.mapSelected updateService cluster.services
                    |> Cluster.asServicesIn cluster

        updateService =
            \service ->
                updateIssues service.issues
                    |> Service.asIssuesIn service

        updateIssues =
            Issues.mapIssue updateIssueDetails

        updateCategory =
            \category ->
                SelectList.Extra.mapSelected updateIssueDetails category.issues
                    |> Category.asIssuesIn category

        updateIssueDetails =
            Issue.setDetails details
    in
    { state | clusters = newClusters }


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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program D.Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

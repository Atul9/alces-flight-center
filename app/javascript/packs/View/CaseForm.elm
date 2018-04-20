module View.CaseForm exposing (view)

import Bootstrap.Modal as Modal
import Category
import Cluster
import Component
import Dict
import Field exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Issue
import Issues
import Markdown
import Maybe.Extra
import Msg exposing (..)
import SelectList
import Service
import State exposing (State)
import Tier exposing (Tier)
import Tier.DisplayWrapper
import Tier.Level as Level exposing (Level)
import Validation
import View.Fields as Fields
import View.PartsField as PartsField exposing (PartsFieldConfig(..))


view : State -> Html Msg
view state =
    let
        submitMsg =
            if State.selectedIssue state |> Issue.isChargeable then
                ChargeableIssuePreSubmissionModal Modal.visibleState
            else
                StartSubmit

        formElements =
            [ issueDrillDownFields state
            , hr [] []
            , dynamicFields state
            ]
    in
    Html.form [ onSubmit submitMsg ] formElements


issueDrillDownFields : State -> Html Msg
issueDrillDownFields state =
    -- These fields allow a user to drill down to identify the particular Issue
    -- and possible solutions (via different Tiers) to a problem they are
    -- having.
    section [] <|
        Maybe.Extra.values
            [ maybeClustersField state
            , maybeServicesField state
            , maybeCategoriesField state
            , issuesField state |> Just
            , maybeComponentsField state
            , tierSelectField state |> Just
            ]


dynamicFields : State -> Html Msg
dynamicFields state =
    -- These fields are very dynamic, and either appear/disappear entirely or
    -- have their content changed based on the currently selected Issue and
    -- Tier.
    let
        fields =
            case selectedTier.level of
                Level.Zero ->
                    -- When a level 0 Tier is selected we want to prevent filling in
                    -- any fields or submitting the form, and only show the rendered
                    -- Tier fields, which should include the relevant links to
                    -- documentation.
                    [ tierFields ]

                _ ->
                    [ subjectField state
                    , tierFields
                    , submitButton state
                    ]

        attributes =
            if sectionDisabled then
                [ class "disabled-section"
                , title <| Validation.unavailableTierErrorMessage state
                ]
            else
                []

        sectionDisabled =
            State.selectedTierSupportUnavailable state

        selectedTier =
            State.selectedTier state

        tierFields =
            dynamicTierFields state
    in
    section attributes fields


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
            (Fields.selectField Field.Cluster
                clusters
                Cluster.extractId
                .name
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
                Fields.selectField Field.Category
                    categories_
                    Category.extractId
                    .name
                    ChangeSelectedCategory
                    state
            )


issuesField : State -> Html Msg
issuesField state =
    let
        selectedServiceAvailableIssues =
            State.selectedServiceAvailableIssues state
    in
    Fields.selectField Field.Issue
        selectedServiceAvailableIssues
        Issue.extractId
        Issue.name
        ChangeSelectedIssue
        state


tierSelectField : State -> Html Msg
tierSelectField state =
    let
        wrappedTiers =
            State.selectedIssue state
                |> Issue.tiers
                |> Tier.DisplayWrapper.wrap
    in
    Fields.selectField Field.Tier
        wrappedTiers
        Tier.DisplayWrapper.extractId
        Tier.DisplayWrapper.description
        ChangeSelectedTier
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
    PartsField.maybePartsField Field.Component
        config
        Component.extractId
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
    PartsField.maybePartsField Field.Service
        config
        Service.extractId
        state
        ChangeSelectedService


subjectField : State -> Html Msg
subjectField state =
    let
        selectedIssue =
            State.selectedIssue state
    in
    Fields.inputField Field.Subject
        selectedIssue
        Issue.subject
        ChangeSubject
        state


dynamicTierFields : State -> Html Msg
dynamicTierFields state =
    let
        tier =
            State.selectedTier state

        renderedFields =
            Dict.toList tier.fields
                |> List.map (renderTierField state)
    in
    div [] renderedFields


renderTierField : State -> ( Int, Tier.Field ) -> Html Msg
renderTierField state ( index, field ) =
    case field of
        Tier.Markdown content ->
            Markdown.toHtml [] content

        Tier.TextInput fieldData ->
            Fields.textField fieldData.type_
                (Field.TierField fieldData)
                fieldData
                .value
                (ChangeTierField index)
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

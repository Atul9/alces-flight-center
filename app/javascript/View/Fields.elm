module View.Fields
    exposing
        ( hiddenFieldWithVisibleErrors
        , selectField
        , textField
        )

import Bootstrap.Badge as Badge
import Bootstrap.Utilities.Spacing as Spacing
import DrillDownSelectList exposing (DrillDownSelectList)
import Field exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode as D
import Maybe.Extra
import Msg exposing (Msg)
import SelectList exposing (Position(..), SelectList)
import State exposing (State)
import String.Extra
import Types
import Validation exposing (Error, ErrorMessage(..))
import View.Utils


selectField :
    Field
    -> DrillDownSelectList a
    -> (a -> Int)
    -> (a -> String)
    -> (a -> Bool)
    -> (String -> msg)
    -> State
    -> Html msg
selectField field items toId toOptionLabel isDisabled changeMsg state =
    let
        fieldOption =
            \position item ->
                option
                    [ toId item |> toString |> value
                    , position == Selected && itemHasBeenSelected |> selected
                    , isDisabled item |> disabled
                    ]
                    [ toOptionLabel item |> text ]

        itemHasBeenSelected =
            case items of
                DrillDownSelectList.Selected _ ->
                    True

                DrillDownSelectList.Unselected _ ->
                    False

        options =
            preSelectionOption :: itemOptions

        preSelectionOption =
            -- Always include this option as the first item, which will only
            -- appear and be selected if no other item has been selected yet
            -- (i.e. if `items` is `Unselected`).
            option
                [ selected True, disabled True, hidden True ]
                [ text "Please select..." ]

        itemOptions =
            DrillDownSelectList.unwrap items
                |> SelectList.mapBy fieldOption
                |> SelectList.toList
    in
    formField field
        select
        [ Html.Events.on "change" (D.map changeMsg Html.Events.targetValue) ]
        options
        state


type alias TextFieldConfig a =
    { fieldType : Types.TextField
    , field : Field
    , toContent : a -> String
    , inputMsg : String -> Msg
    }


textField : TextFieldConfig a -> State -> a -> Html Msg
textField config state item =
    let
        content =
            config.toContent item

        ( element, additionalAttributes ) =
            case config.fieldType of
                Types.Input ->
                    ( input, [] )

                Types.TextArea ->
                    ( textarea, [ rows 10 ] )

        attributes =
            [ onInput config.inputMsg
            , value content
            ]
                ++ additionalAttributes
    in
    formField config.field element attributes [] state


type alias HtmlFunction msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


formField :
    Field
    -> HtmlFunction msg
    -> List (Attribute msg)
    -> List (Html msg)
    -> State
    -> Html msg
formField field htmlFn additionalAttributes children state =
    let
        fieldName =
            Field.name field

        fieldHelpText =
            Field.helpText field

        fieldIsUnavailable =
            tierIsUnavailable && Field.isDynamicField field

        tierIsUnavailable =
            State.selectedTierSupportUnavailable state

        identifier =
            fieldIdentifier fieldName

        requiredBadge =
            if optional then
                View.Utils.nothing
            else
                Badge.badgeLight [ Spacing.ml1 ] [ text "Required" ]

        optional =
            case field of
                Field.TierField data ->
                    data.optional

                _ ->
                    False

        attributes =
            List.append
                [ id identifier
                , class (formControlClasses field errors)
                , disabled fieldIsUnavailable
                , attribute "aria-describedBy" helpIdentifier
                ]
                additionalAttributes

        formElement =
            htmlFn attributes children

        helpElement =
            case fieldHelpText of
                Just h ->
                    small
                        [ id helpIdentifier, class "form-text text-muted" ]
                        [ text h ]

                Nothing ->
                    View.Utils.nothing

        helpIdentifier =
            identifier ++ "-help"

        errors =
            Validation.validateField field state
    in
    View.Utils.showIfParentFieldSelected state field <|
        div [ class "form-group" ]
            [ label
                [ for identifier ]
                [ text fieldName ]
            , requiredBadge
            , formElement
            , helpElement
            , validationFeedback errors
            ]


hiddenFieldWithVisibleErrors : Field -> State -> Html msg
hiddenFieldWithVisibleErrors field state =
    let
        errors =
            Validation.validateField field state
    in
    div []
        [ input
            -- Bootstrap requires an input with appropriate classes as a
            -- sibling in order to show an `invalid-feedback` `div`.
            [ type_ "hidden"
            , class <| formControlClasses field errors
            ]
            []
        , validationFeedback errors
        ]


fieldIdentifier : String -> String
fieldIdentifier fieldName =
    String.toLower fieldName
        |> String.Extra.dasherize


formControlClasses : Field -> List Error -> String
formControlClasses field errors =
    "form-control " ++ bootstrapValidationClass field errors


bootstrapValidationClass : Field -> List Error -> String
bootstrapValidationClass field errors =
    let
        validationClass =
            if List.isEmpty errors then
                "is-valid"
            else
                "is-invalid"
    in
    if Field.hasBeenTouched field then
        validationClass
    else
        -- If the field is not considered to have been touched yet then just
        -- give nothing, rather than showing either success or failure, to
        -- avoid showing the user many errors for fields they haven't yet
        -- looked at.
        ""


validationFeedback : List Error -> Html msg
validationFeedback errors =
    let
        combinedErrorMessages =
            List.map unpackErrorMessage errorMessages
                |> Maybe.Extra.values
                |> String.join "; "

        errorMessages =
            List.map Tuple.second errors

        unpackErrorMessage =
            \error ->
                case error of
                    Empty ->
                        Nothing

                    Message message ->
                        Just message
    in
    div
        [ class "invalid-feedback" ]
        [ text combinedErrorMessages ]

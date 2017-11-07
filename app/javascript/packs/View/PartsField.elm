module View.PartsField exposing (maybePartsField)

import Cluster exposing (Cluster)
import ClusterPart exposing (ClusterPart)
import FieldValidation exposing (FieldValidation(..))
import Html exposing (Html)
import Issue exposing (Issue)
import SelectList exposing (Position(..), SelectList)
import State exposing (State)
import String.Extra
import SupportType exposing (HasSupportType)
import View.Fields as Fields


maybePartsField :
    String
    -> (Cluster -> SelectList (ClusterPart a))
    -> (ClusterPart a -> Int)
    -> Maybe (ClusterPart a)
    -> (Issue -> Bool)
    -> State
    -> (String -> msg)
    -> Maybe (Html msg)
maybePartsField partName partsForCluster toId singlePart issueRequiresPart state changeMsg =
    let
        fieldLabel =
            String.Extra.toTitleCase partName

        partsForSelectedCluster =
            SelectList.selected state.clusters |> partsForCluster

        selectedIssue =
            State.selectedIssue state

        partRequired =
            issueRequiresPart selectedIssue

        validatePart =
            FieldValidation.validateWithErrorForItem
                (errorForClusterPart partName)
                (State.clusterPartAllowedForSelectedIssue state issueRequiresPart)

        labelForPart =
            \part ->
                case part.supportType of
                    SupportType.Advice ->
                        part.name ++ " (self-managed)"

                    _ ->
                        part.name
    in
    case singlePart of
        Just part ->
            -- We're creating a Case for a specific part => don't want to allow
            -- selection of another part, but do still want to display any
            -- error between this part and selected Issue.
            Just (Fields.hiddenInputWithVisibleError part validatePart)

        Nothing ->
            if partRequired then
                -- Issue requires a part of this type => allow selection from
                -- all parts of this type for Cluster.
                Just
                    (Fields.selectField fieldLabel
                        partsForSelectedCluster
                        toId
                        labelForPart
                        validatePart
                        changeMsg
                    )
            else
                -- Issue does not require a part of this type => do not show
                -- any select.
                Nothing


errorForClusterPart : String -> HasSupportType a -> String
errorForClusterPart partName part =
    if SupportType.isManaged part then
        "This " ++ partName ++ " is already fully managed."
    else
        "This "
            ++ partName
            ++ """ is self-managed; if required you may only request
            consultancy support from Alces Software."""

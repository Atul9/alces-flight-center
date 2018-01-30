module Issue
    exposing
        ( Id(..)
        , Issue
        , decoder
        , details
        , detailsValid
        , extractId
        , isChargeable
        , name
        , requiresComponent
        , sameId
        , setDetails
        , supportType
        )

import Json.Decode as D
import SupportType exposing (SupportType(..))
import Utils


type Issue
    = ComponentRequiredIssue IssueData
    | StandardIssue IssueData


type alias IssueData =
    { id : Id
    , name : String
    , details : String
    , supportType : SupportType
    , chargeable : Bool
    }


type Id
    = Id Int


decoder : D.Decoder Issue
decoder =
    let
        createIssue =
            \id ->
                \name ->
                    \requiresComponent ->
                        \detailsTemplate ->
                            \supportType ->
                                \chargeable ->
                                    let
                                        data =
                                            IssueData id name detailsTemplate supportType chargeable
                                    in
                                    if requiresComponent then
                                        ComponentRequiredIssue data
                                    else
                                        StandardIssue data
    in
    D.map6 createIssue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "detailsTemplate" D.string)
        (D.field "supportType" SupportType.decoder)
        (D.field "chargeable" D.bool)


detailsValid : Issue -> Bool
detailsValid issue =
    details issue |> String.isEmpty |> not


extractId : Issue -> Int
extractId issue =
    case data issue |> .id of
        Id id ->
            id


requiresComponent : Issue -> Bool
requiresComponent issue =
    case issue of
        ComponentRequiredIssue _ ->
            True

        StandardIssue _ ->
            False


name : Issue -> String
name issue =
    data issue |> .name


details : Issue -> String
details issue =
    data issue |> .details


setDetails : String -> Issue -> Issue
setDetails details issue =
    let
        data_ =
            data issue

        newData =
            { data_ | details = details }
    in
    case issue of
        ComponentRequiredIssue _ ->
            ComponentRequiredIssue newData

        StandardIssue _ ->
            StandardIssue newData


supportType : Issue -> SupportType
supportType issue =
    data issue |> .supportType


isChargeable : Issue -> Bool
isChargeable issue =
    data issue |> .chargeable


data : Issue -> IssueData
data issue =
    case issue of
        ComponentRequiredIssue data ->
            data

        StandardIssue data ->
            data


sameId : Id -> Issue -> Bool
sameId id issue =
    data issue |> Utils.sameId id

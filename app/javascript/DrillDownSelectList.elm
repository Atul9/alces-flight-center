module DrillDownSelectList exposing (..)

import SelectList exposing (SelectList)
import SelectList.Extra


type DrillDownSelectList a
    = Unselected (SelectList a)
    | Selected (SelectList a)


unwrap : DrillDownSelectList a -> SelectList a
unwrap selectList =
    case selectList of
        Unselected s ->
            s

        Selected s ->
            s



-- XXX Rename arguments and/or simplify functions in this file?
-- XXX Or pull in or reference docs from SelectList.Extra?


select : (a -> Bool) -> DrillDownSelectList a -> DrillDownSelectList a
select isSelectable selectList =
    unwrap selectList
        |> SelectList.select isSelectable
        -- XXX Document why this always returns `Selected`?
        |> Selected


selected : DrillDownSelectList a -> a
selected =
    -- XXX Should this actually return a Maybe, with Nothing when nothing yet
    -- selected?
    unwrap >> SelectList.selected


mapSelected : (a -> a) -> DrillDownSelectList a -> DrillDownSelectList a
mapSelected transform selectList =
    unwrap selectList
        |> SelectList.Extra.mapSelected transform
        -- XXX Should this always return `Selected`?
        |> Selected


nestedSelect :
    DrillDownSelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (b -> Bool)
    -> DrillDownSelectList a
nestedSelect selectList getNested asNestedIn isSelectable =
    updateNested
        selectList
        getNested
        asNestedIn
        (select isSelectable)


updateNested :
    -- XXX Collapse back into simple `updateNested` function?
    -- XXX Can this just use function from SelectList.Extra?
    DrillDownSelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (DrillDownSelectList b -> DrillDownSelectList b)
    -> DrillDownSelectList a
updateNested selectList getNested asNestedIn transform =
    -- XXX Can this just use function from SelectList.Extra?
    let
        updateNested =
            \item ->
                getNested item
                    |> transform
                    |> asNestedIn item
    in
    mapSelected updateNested selectList


toList : DrillDownSelectList a -> List a
toList =
    unwrap >> SelectList.toList



-- XXX Remove following once all items use DrillDownSelectList?


nestedDrillDownSelect :
    SelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (b -> Bool)
    -> SelectList a
nestedDrillDownSelect selectList getNested asNestedIn isSelectable =
    -- XXX Rename as with `updateNestedDrillDownSelectList`?
    updateNestedDrillDownSelectList
        selectList
        getNested
        asNestedIn
        (select isSelectable)


updateNestedDrillDownSelectList :
    -- XXX Collapse back into simple `updateNested` function?
    -- XXX Can this just use function from SelectList.Extra?
    SelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (DrillDownSelectList b -> DrillDownSelectList b)
    -> SelectList a
updateNestedDrillDownSelectList selectList getNested asNestedIn transform =
    let
        updateNested =
            \item ->
                getNested item
                    |> transform
                    |> asNestedIn item
    in
    SelectList.Extra.mapSelected updateNested selectList

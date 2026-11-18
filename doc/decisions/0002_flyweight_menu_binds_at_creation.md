# 0002 The flyweight menu binds its buttons when the instance is created

**Status** — accepted, 2026-11-14 (Part 2 Phase 2, Task 1), on the owner's review question of 2026-11-15.

**Context** — [FlyweightMenuSource] shares one list of menu items across many menus (every `VarIOFieldWithMenu` on the
monitor page has its own selection, the same hundred item views). An item pressed in one menu must update that menu's
notifier only. The first implementation resolved the menu at build time: each item was a widget whose `build` called
`FlyweightMenuContext.of<T>(context)`, an `InheritedNotifier` that every anchor wrapped around its panel. The file header
named the alternative, an init-time shallow copy, and did not take it.

Three things were wrong with the build-time lookup:

1. `dependOnInheritedWidgetOfExactType` registers the item as a dependent of the notifier. An item needs the menu
   reference once; wiring it to the value means every selection rebuilds every item in the open panel.
2. An item's correctness depended on its position in the element tree. It worked only because `MenuAnchor` renders its
   panel through `OverlayPortal`, which keeps the panel a descendant of the anchor; an `OverlayEntry`-based anchor would
   have failed the assert, and an item placed anywhere else did.
3. The exact-type match made `T` a lookup key, so `T` had to be threaded through `VarSelectableBuilder` and
   `VarIOFieldWithMenu` for the lookup to succeed, not for any value it carried.

Why it worked and still sat outside the intent of `InheritedWidget`. The lookup did resolve correctly: an element
carries a map of its inherited ancestors, and `OverlayPortal` gives the panel's elements the anchor's map, so
`dependOnInheritedWidgetOfExactType` found the right context in O(1) without walking. The mechanism, though, exists to
carry immutable configuration down the tree (theme, media query, locale) and to rebuild the descendants that read it
when that configuration changes. The old menu ran it the other way: the inherited widget carried a mutable notifier,
and a shared item object used its render position to decide which notifier to write to on press, so a command flowed
up through a channel built for configuration flowing down, and the read that only needed a reference registered a
rebuild dependency as a side effect. The same widget object meant different things in different places, which is
dynamic scoping; a closure bound at creation is lexical binding, which is what the new design uses.

```mermaid
flowchart TB
  subgraph INTENT["InheritedWidget as designed: configuration flows DOWN"]
    direction TB
    T["Theme / MediaQuery / Localizations<br/>immutable data owned by an ancestor"]
    D1["descendant A reads it"]
    D2["descendant B reads it"]
    T -- "of(context): a read" --> D1
    T -- "of(context): a read" --> D2
    T -. "the data changes, so dependents rebuild:<br/>that is what the registered dependency is for" .-> D1
  end
  subgraph USED["How the old menu used it: a command flows UP"]
    direction TB
    CX["FlyweightMenuContext<br/>carries a MUTABLE notifier (the extrinsic state)"]
    S["one shared FlyweightMenuItem object,<br/>rendered under menu X in one panel<br/>and under menu Y in another"]
    S -- "of(context) to learn WHICH menu it is inside<br/>(identity by position)" --> CX
    S -- "on press: menu.value = key<br/>a write, upward, into the ancestor's state" --> CX
    CX -. "the read registered a dependency,<br/>so the write rebuilds every item" .-> S
  end
  classDef ok fill:#e3f2e1,stroke:#2e7d32,color:#0b3d0b
  classDef bad fill:#fde2e1,stroke:#b3261e,color:#410e0b
  class T,D1,D2 ok
  class CX,S bad
```

```mermaid
flowchart LR
  subgraph OLD["Old: dynamic scope"]
    direction TB
    O1["FlyweightMenuItem(key A)<br/>one object, no owner"]
    O2["rendered under X: press writes X<br/>rendered under Y: press writes Y<br/>rendered elsewhere: assert"]
    O1 -- "meaning resolved at build time<br/>from the enclosing tree" --> O2
  end
  subgraph NEW["New: lexical binding"]
    direction TB
    N1["X = source.create()"]
    N2["MenuItemButton(onPressed: () => X.value = A,<br/>child: shared view A)"]
    N1 -- "the closure captures X once,<br/>wherever the button is later rendered" --> N2
  end
  classDef bad fill:#fde2e1,stroke:#b3261e,color:#410e0b
  classDef ok fill:#e3f2e1,stroke:#2e7d32,color:#0b3d0b
  class O1,O2 bad
  class N1,N2 ok
```

The structure of the old design, and one press in it:

```mermaid
flowchart TB
  subgraph SRC["FlyweightMenuSource (shared, const)"]
    IA["FlyweightMenuItem A: key A + child A<br/>(a Widget)"]
    IB["FlyweightMenuItem B: key B + child B"]
    IH["FlyweightMenuItem header: key null"]
  end
  subgraph X["MenuAnchorBuilder X"]
    MX["FlyweightMenu X<br/>ValueNotifier"]
    CX["FlyweightMenuContext X<br/>InheritedNotifier, exact type keyed on T"]
    PX["MenuAnchor panel X<br/>(OverlayPortal keeps it under CX)"]
  end
  subgraph Y["MenuAnchorBuilder Y"]
    MY["FlyweightMenu Y"]
    CY["FlyweightMenuContext Y"]
    PY["MenuAnchor panel Y"]
  end
  IA -. "same widget object in both panels" .-> PX
  IA -. "same widget object in both panels" .-> PY
  MX --> CX --> PX
  MY --> CY --> PY
  PX -- "1. every item's build(): dependOnInheritedWidgetOfExactType<br/>registers the item as a dependent" --> CX
  MX -- "2. value change notifies dependents:<br/>all N items rebuild" --> CX
  PX -- "3. works only while the panel is a descendant<br/>(OverlayPortal); an OverlayEntry anchor asserts" --> CX
  classDef bad fill:#fde2e1,stroke:#b3261e,color:#410e0b
  class CX,CY bad
```

```mermaid
sequenceDiagram
  participant U as User
  participant I as FlyweightMenuItem.build (one of N, panel X)
  participant C as FlyweightMenuContext X
  participant M as FlyweightMenu X (notifier)
  participant N as the other N-1 items in panel X
  I->>C: dependOnInheritedWidgetOfExactType (at build)
  C-->>I: menu X (dependency registered)
  U->>I: press item A
  I->>M: value = A
  M->>C: notifyListeners
  C->>I: rebuild (dependent)
  C->>N: rebuild all other dependents
  N->>C: N-1 lookups again
  Note over C,N: the items needed a reference once<br/>but were wired to the value instead
```

**Decision** — the init-time shallow copy. The flyweight's intrinsic state, the item key and its view widget, stays
shared and immutable: [FlyweightMenuItem] is plain data `(itemKey, child)`, not a widget. The extrinsic state, which
notifier a press updates, is bound when the instance is created: [FlyweightMenu] composes its source (it no longer
extends it) and builds one thin `MenuItemButton` per item whose `onPressed` closure sets its own `value`. Anchors receive
`menu.menuItems` explicitly; `MenuAnchorBuilder` still creates and disposes the instance. The `InheritedNotifier`
(`FlyweightMenuContext`) and the three classes that only existed around it (`FlyweightMenuOverlay`,
`MenuListenableBuilder`, the throwing `FlyweightMenuTheme`) had no user outside the folder and are deleted.

```mermaid
flowchart TB
  subgraph SRC["FlyweightMenuSource (shared, const)"]
    IA["FlyweightMenuItem A: key A + child A<br/>(plain data, not a Widget)"]
    IB["FlyweightMenuItem B: key B + child B"]
    IH["FlyweightMenuItem header: key null"]
  end
  subgraph X["FlyweightMenu X = source.create()"]
    NX["ValueNotifier X"]
    BX["menuItems (built once per instance):<br/>MenuItemButton(onPressed: X.value = A, child A)<br/>MenuItemButton(onPressed: X.value = B, child B)<br/>MenuItemButton(onPressed: null, header)"]
  end
  subgraph Y["FlyweightMenu Y = source.create()"]
    NY["ValueNotifier Y"]
    BY["menuItems bound to Y"]
  end
  IA -. "child shared by identity" .-> BX
  IA -. "child shared by identity" .-> BY
  BX -- "closure bound at create()" --> NX
  BY -- "closure bound at create()" --> NY
  AX["MenuAnchorOverlay / MenuAnchorButton<br/>menuItems: X.menuItems"] --> BX
  KX["ValueListenableBuilder (key widget)<br/>+ optional onPressed"] -- "explicit listeners only" --> NX
  classDef good fill:#e3f2e1,stroke:#2e7d32,color:#0b3d0b
  class BX,BY good
```

```mermaid
sequenceDiagram
  participant U as User
  participant B as MenuItemButton (X, item A)
  participant M as FlyweightMenu X (notifier)
  participant L as ValueListenableBuilder + onPressed
  U->>B: press
  B->>M: value = A (closure bound at create)
  M->>L: notifyListeners
  Note over B: no context lookup, no rebuild of the panel items,<br/>T is a value type again, not a lookup key
```

**Consequences**
- Each instance holds N `MenuItemButton` objects (a few words each); the item views, the expensive part, are still one
  object per item for the whole app. `test/widgets/flyweight_menu_test.dart` pins identity sharing, per-instance
  notification, the disabled header, disposal, and that a selection does not replace the item buttons.
- A selection notifies the explicit listeners only (the key widget's `ValueListenableBuilder`, the optional `onPressed`).
- An item list can be rendered under any anchor; nothing depends on `OverlayPortal`.
- `T` still types the keys and the notifier, but no longer selects an inherited widget. Whether it earns its place on
  [FlyweightMenu] at all is open (the review's question); a plain `Object?` key type would remove the generic.
- `flyweight_menu_widgets.dart` lost its `FlyweightMenuContext` wrappers and `FlyweightMenuOverlay` here; the same file
  then took two unrelated changes in later tasks, so its diff reads larger than this decision: Task 4 removed the
  unused private `MenuAnchorOverlay._` and converted the class to a primary constructor, and Task 11 added keyboard
  access and semantics (`Semantics` + `CallbackShortcuts` around the anchor, the menu button's tooltip).

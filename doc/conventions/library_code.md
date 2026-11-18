# Changing library code

`cmdr` and `struct_data` are consumed from outside, and every diff is read. These rules keep a change the size of its
reason. They come from review fixes reverted between 2026-11-12 and 2026-11-15.

| Rule | Instead of | Instance |
|---|---|---|
| A fix goes inside the expression or loop the file already has | a new construction that makes the fix fit | `arrayAt`: the view-derived default length inside its one call |
| A constraint every caller already meets is an `assert` | runtime checks, clamps or recomputation | `arrayAt` asserts `testArray`; `MemWriteRequest.build` keeps one size check |
| An anomaly something downstream absorbs gets a comment, and a test pinning it | a guard | `_Angle16.encode` returns 65536 for a tiny negative value; the device wraps it to 0 |
| A type parameter is carried through, or the abstraction is not built | pinning it so the code typechecks | `BinarizableField<V, B extends NativeType>` |

## Fix inside the existing shape
- Needing a new construction to make a fix fit is the signal to look again, not to proceed.
- A framework-managed lifecycle stays: `ListenableBuilder` owns subscribe, swap and dispose. Manual
  `addListener` / `removeListener` to avoid a side effect in a build callback buys nothing.
- A null or unknown check belongs to the one layer that already does it (`List<T>.resolve`), not to a new interface
  member implemented five times. Grep for callers first; an API with no callers is deleted, not generalised.
- "Finish all slices, then report the first error" is a proposal, not a requirement: stop at the first failure, in the
  idiom of the sibling function.
- Rounding and range go to the layer that knows the width: `BinaryQuantityCodec.encode` clamps to `binaryRange`.

## Assert a constraint that holds
- Code that works because its inputs are constrained states the condition in an `assert`: const sizes, codec limits,
  struct extents, lengths a caller derives from the same view.
- A runtime-checked variant (`...OrNull`) tests the same predicate the assert names: one condition, two uses.
- Runtime handling is for inputs no caller can bound: wire data, user input, files.

## Document an absorbed anomaly
- Follow the value to its consumer before adding a guard. When the device wraps it, a caller bounds it, or nothing
  calls twice, one comment names the anomaly and who absorbs it.
- An error on ordinary inputs is a bug, not an anomaly. `viewValue ~/ coefficient` gave `0.3 ~/ 0.1 == 2` and moved
  35-50 % of displayed words on re-entry; `(viewValue / coefficient).round()` fixed it for about 1.5 ns a call.

## Carry a type parameter, or don't abstract
- Pinning a parameter of the type you build on (`TypedField<T>` to `TypedField<Uint16>`) turns the caller's generality
  into your private constant.
- Dart has no intersection bounds. A synthetic `implements A, B` interface made only to get one says the two concerns
  belong in different layers: view and state up to `dataMap`, serialization per blob.
- Seven duplicated lines across two classes beat a generic machine that has to be un-generalised later.

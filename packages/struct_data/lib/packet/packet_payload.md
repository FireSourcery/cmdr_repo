# What a payload may depend on

Source: `packages/struct_data/lib/packet/packet_id.dart`, `Payload`.

Its own bytes, and the header of the frame carrying them. Not the request that provoked
it.

Two mechanisms were in play. The previous Dart module threaded a `PayloadMeta` from the
request into the response's `parse`, so a reply could be decoded using what the request
had recorded. The device side instead hands a handler the metadata of the frame it is
decoding — `Packet_Xfer_T.p_RxMeta`. Only the second survives here.

The empirical reason: across every `Payload` implementation in the Mot table, the
request-state parameter is accepted and never read. Not once. It was a channel with no
traffic, and the responses that look like they need it — a variable-length read — get
their count from the payload region's own length instead.

The design reason is that the two are not alternatives; they answer different questions,
and only one is a question a decoder should be asking. Giving a decoder the header of
*its own* frame is the standard arrangement: Kaitai Struct exposes `_parent` and `_root`
to a substructure, Construct threads a parse context down into nested subconstructs, and
HTTP/2 implementations decode a frame body against the type and flags from that frame's
header. A body governed by fields in its own header is ordinary.

Threading values from a *different* frame is the unusual one. RPC frameworks — gRPC,
Thrift, Cap'n Proto — take the response *type* from the request, which this design does
too through `PacketRequestId.responseId`, but decode the response's contents from the
response alone. A decoder that needs the request to make sense of the reply stops working
the moment a frame is retransmitted, arrives out of order, or is read back from a log.

The build direction is not the mirror of this: see `Payload.build`.

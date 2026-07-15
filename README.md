# HelloPay_Simulator

HelloPay Simulator

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Phase 3 simulator domain layer

The simulator includes centralized HelloPay-inspired light theme tokens,
immutable protocol models, fictional test cards, scenario presets, a shared
simulator engine, and Riverpod provider entry points. Demo mode and a future
local API mode use the same engine and validation rules.

Refunds can optionally link to an original simulator transaction ID. This is a
simulator behavior for testing refundable balances; it is not a claim about
the production HelloPay protocol, whose source material does not clearly
define original-transaction linking.

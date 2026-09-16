---
name: react-native-conventions
description: React Native conventions - navigation, styling, lists, platform differences, native modules, storage, permissions and testing. Use when writing or reviewing React Native or Expo code, or anything in a mobile app project.
---

# React Native Conventions

Mobile is not the web with different components. The constraints that matter
are startup time, list performance, memory, offline behaviour and the fact that
an app store release cannot be hotfixed in five minutes.

## Project Shape

```
src/
├── app/ or navigation/   # route definitions
├── screens/              # one per route, PascalCase
├── components/           # shared presentational
├── hooks/
├── services/             # API clients, storage wrappers
├── store/
└── types/
```

- Screens compose; components render
- No business logic in a screen - push it into a hook or service
- Absolute imports via path aliases, not `../../../`

## TypeScript

- Required. Type navigation params, API responses and storage shapes.
- Type the navigator so route params are checked:

```tsx
type RootStackParamList = {
    Home: undefined;
    Order: { orderId: string };
};
```

- No `any` on an API boundary. Parse and validate what comes off the network -
  a backend field going null should surface at the boundary, not three screens
  later.

## Navigation

- One navigator definition, typed, in one place
- Never navigate by string literal where a typed helper exists
- Pass IDs as params, not whole objects - params are serialised and belong in
  deep links
- Fetch by ID on the destination screen
- Handle the back gesture and hardware back button explicitly on anything with
  unsaved state

## Styling

- `StyleSheet.create` or a styling library, chosen once per project and used
  consistently
- No inline style objects in render - they allocate every frame
- Define spacing, colour and typography scales once; never scatter magic numbers
- `useWindowDimensions`, not `Dimensions.get()` - the latter does not update on
  rotation or split view
- Respect safe areas with `useSafeAreaInsets` rather than hardcoded padding
- Test both light and dark appearance

## Lists

This is where mobile apps actually fall over.

- `FlatList` or `FlashList` - never `map()` over a large array inside a
  `ScrollView`
- `keyExtractor` returning a stable ID
- Memoise `renderItem` and the item component
- `getItemLayout` when rows are a fixed height
- `initialNumToRender` tuned to roughly one screenful
- Pagination on anything unbounded
- Never nest a `VirtualizedList` inside a `ScrollView` on the same axis

## Performance

- `React.memo` on list item components, with a real comparison if props are
  objects
- `useCallback` for anything passed to a memoised child
- Keep JS work off the frame: heavy transforms belong in `InteractionManager`
  or a worklet
- Animate with Reanimated on the UI thread; avoid `Animated` with
  `useNativeDriver: false`
- Images need explicit dimensions and a caching strategy - unbounded remote
  images are the most common memory problem

## Platform Differences

- `Platform.select` for genuine divergence, not to paper over a layout bug
- `.ios.tsx` / `.android.tsx` when a component's implementations really differ
- Test both. A shadow that looks right on iOS is usually invisible on Android,
  which needs `elevation`.
- Keyboard handling differs - `KeyboardAvoidingView` behaviour is `padding` on
  iOS and usually `height` on Android

## Storage and Offline

- `AsyncStorage` is unencrypted. Tokens and anything sensitive go in Keychain /
  Keystore via a secure storage library.
- Assume the network is absent, slow or lying - every request needs a timeout
  and a failure path the user can see
- Cache with an explicit invalidation story; a stale screen with no refresh
  affordance is a bug
- Queue writes made offline rather than dropping them silently

## Permissions

- Request at the moment of use, with context, never on launch
- Handle all three states: granted, denied, permanently denied
- A permanently denied permission needs a route to system settings
- Declare only what the app uses - an unjustified permission is a store review
  rejection

## Native Modules and Dependencies

- Check maintenance status before adding a dependency with native code - an
  unmaintained native module blocks your next RN upgrade
- Prefer an Expo module where one exists
- Pin versions and know which native dependencies need a rebuild versus an OTA
  update

## Error Handling

- Error boundaries around each screen, not one at the root
- Report to crash reporting with context, do not swallow
- A network failure gets a retry affordance, never a blank screen

## Testing

- Unit-test hooks and services
- React Native Testing Library for component behaviour; query by accessibility
  role and label, not test IDs, where possible
- Detox or Maestro for the flows that carry money or auth
- Test on a real low-end Android device before release - the simulator will lie
  to you about performance

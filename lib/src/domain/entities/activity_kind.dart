/// The two kinds of session a user is in at any time.
///
/// `working` corresponds to the avatar-with-laptop screen and `walking` to
/// the sneaker screen in the reference designs.
enum ActivityKind { working, walking }

extension ActivityKindX on ActivityKind {
  ActivityKind get opposite => switch (this) {
        ActivityKind.working => ActivityKind.walking,
        ActivityKind.walking => ActivityKind.working,
      };
}

# Beacon

A Process that periodically reaches a target at a fixed interval.

## Example

When configuring the `Beacon`, the `|>` operator can be used to
write a cleaner code.

```elixir
{:ok, r} = Beacon.start_link(self())

r |> Beacon.set_periodic_callback(3, &(send(&1, :ping)))
  |> Beacon.set_duration(10)
  |> Beacon.enable
```

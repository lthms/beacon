# A process that periodically reaches a target at a fixed interval.
# Copyright (C) 2017 Thomas Letan
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

defmodule Beacon do
  use GenServer

  @typedoc """
  The `Beacon` name.
  """
  @type name :: atom | {:global, term} | {:via, module, term}

  @typedoc """
  Option values used by the `start*` functions. The semantics is the
  same as `GenServer.option`.
  """
  @type option :: {:name, name} | {:spawn_opt, Process.spawn_opt}

  @typedoc """
  Return values of `start*` functions.
  """
  @type on_start :: {:ok, pid}
  | :ignore
  | {:error, {:already_started, pid} | term}

  @moduledoc """
  A Process that periodically reaches a target at a fixed interval.

  ## Examples

  When configuring the `Beacon`, the `|>` operator can be used to
  write a cleaner code.

      {:ok, r} = Beacon.start(self())

      r |> Beacon.set_periodic_callback(3, &(send(&1, :ping)))
        |> Beacon.set_duration(10)
        |> Beacon.enable
  """

  @typedoc """
  The beacon reference.
  """
  @type t :: pid | name | {atom, node}

  @typedoc """
  The target reference.
  """
  @type target :: any

  @typedoc """
  A function called at a certain time in order for the `Beacon` to
  reach its target.
  """
  @type callback :: (target -> no_return)

  defmodule State do
    alias Lkn.Foundation.Beacon
    @moduledoc false

    defstruct [
      :started,
      :target,
      :duration,
      :period,
      :periodic_callback,
      :term_callback,
      :cancel_callback,
    ]

    @type t :: %State{
      started: boolean,
      target: Beacon.target | (),
      duration: integer | (),
      period: integer | (),
      periodic_callback: Beacon.callback | (),
      term_callback: Beacon.callback | (),
      cancel_callback: Beacon.callback | (),
    }

    @spec new(Beacon.target) :: t
    def new(target) do
      %State{started: false, target: target}
    end

    @spec set_periodic(t, integer, Beacon.callback) :: t
    def set_periodic(state = %State{started: false}, period, callback) do
      %State{state|period: period, periodic_callback: callback}
    end
    def set_periodic(state = %State{started: true}, _period, _callback) do
      state
    end

    @spec set_duration(t, integer) :: t
    def set_duration(state = %State{started: false}, duration) do
      %State{state|duration: duration}
    end
    def set_duration(state = %State{started: true}, _duration) do
      state
    end

    @spec set_term(t, Beacon.callback) :: t
    def set_term(state = %State{started: false}, callback) do
      %State{state|term_callback: callback}
    end
    def set_term(state = %State{started: true}, _callback) do
      state
    end
  end

  @spec start(target, [option]) :: on_start
  @doc """
  Start a `Beacon` process without links, that is outside a
  supervision tree.

  See `start_link/2` for more information.
  """
  def start(target, opt \\ []) do
    GenServer.start_link(__MODULE__, State.new(target), opt)
  end

  @spec start_link(target, [option]) :: on_start
  @doc """
  Start a `Beacon` process linked to the current process.

  A Beacon cannot be used right after its creation but needs to be
  configured first. For that, the Beacon setters (such
  as`set_periodic_callback/3`, `set_duration/3`, etc.) have to be used
  before `start/1` can be called.
  """
  def start_link(target, opt \\ []) do
    GenServer.start_link(__MODULE__, State.new(target), opt)
  end

  @spec set_periodic_callback(t, integer, callback) :: t
  @doc """
  Set a periodic callback to a given Beacon.

  Once started, the Beacon will periodically executes the `callback`
  until its termination.

  If the Beacon has already been started (using `start/1`), then this
  call is effectless. If `set_periodic_callback/3` has already been
  called but the Beacon has not been started, then the new call
  overwrite the Beacon state.

  The several setters provided by this module can be chained using the
  pipe operator.
  """
  def set_periodic_callback(beacon, period, callback) do
    GenServer.cast(beacon, {:set_periodic_callback, period, callback})
    beacon
  end

  @doc """
  Set a duration to a given Beacon and optionally a callback.

  Once started, the Beacon will end after `duration` milliseconds. If
  a callback has been defined, it is executed.

  If the Beacon has already been started (using `start/1`), then this
  call is effectless. If `set_duration/2` (or `set_duration/3`) has
  already been called but the Beacon has not been started, then the
  new call overwrite the Beacon state.

  The several setters provided by this module can be chained using the
  pipe operator.
  """
  @spec set_duration(t, integer) :: t
  @spec set_duration(t, integer, callback) :: t
  def set_duration(beacon, duration) do
    GenServer.cast(beacon, {:set_duration, duration})

    beacon
  end
  def set_duration(beacon, duration, callback) do
    beacon
    |> set_duration(duration)
    |> GenServer.cast({:set_term_callback, callback})

    beacon
  end

  @spec set_cancel_callback(t, callback) :: t
  @doc """
  Set a callback to execute in case the Beacon is cancelled using
  `cancel/1`.

  If the Beacon has already been started (using `start/1`), then this
  call is effectless. If `set_cancel_callback/3` has already been
  called but the Beacon has not been started, then the new call
  overwrite the Beacon state.

  The several setters provided by this module can be chained using the
  pipe operator.
  """
  def set_cancel_callback(beacon, callback) do
    GenServer.cast(beacon, {:set_cancel_callback, callback})
    beacon
  end

  @spec enable(t) :: :ok
  @doc """
  Start the execution of the given `Beacon`.
  """
  def enable(beacon) do
    GenServer.cast(beacon, :enable)
  end

  @spec cancel(t) :: :ok
  @doc """
  Cancel a Beacon before it has a chance to terminates.

  The regular workflow for `cancel/1` is to be called *after*
  `start/1`. Yet, for some reason, one might want to "cancel" a
  `Beacon` *before* (that is, terminates the underlying `GenServer`).
  """
  def cancel(beacon) do
    GenServer.cast(beacon, :cancel)
  end

  def handle_cast(:enable, state) do
    case state do
      %State{period: nil, duration: d} ->
        Process.send_after(self(), :fire_term, d)
      %State{period: p, duration: nil} ->
        Process.send_after(self(), :fire_periodic, p)
      %State{period: p, duration: d} ->
        Process.send_after(self(), :fire_periodic, p)
        Process.send_after(self(), :fire_term, d)
    end
    {:noreply, state}
  end

  def handle_cast({:set_periodic_callback, period, callback}, state) do
    {:noreply, State.set_periodic(state, period, callback)}
  end

  def handle_cast({:set_cancel_callback, c}, state) do
    {:noreply, %{state | cancel_callback: c}}
  end

  def handle_cast({:set_duration, duration}, state) do
    {:noreply, State.set_duration(state, duration)}
  end

  def handle_cast({:set_term_callback, c}, state) do
    {:noreply, State.set_term(state, c)}
  end

  def handle_cast(:cancel, state) do
    case state do
      %State{cancel_callback: nil} ->
        :ok
      %State{cancel_callback: eff, target: t} ->
        eff.(t)
    end

    {:stop, :normal, state}
  end

  def handle_info(:fire_periodic, state) do
    case state do
      %State{period: p, periodic_callback: c, target: t} ->
        c.(t)
        Process.send_after(self(), :fire_periodic, p)
    end
    {:noreply, state}
  end

  def handle_info(:fire_term, state) do
    case state do
      %State{term_callback: nil} ->
        :ok
      %State{term_callback: c, target: t} ->
        c.(t)
    end

    {:stop, :normal, state}
  end
end

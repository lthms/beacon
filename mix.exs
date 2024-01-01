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

defmodule Beacon.Mixfile do
  use Mix.Project

  def project do
    [
      app: :beacon,
      version: "1.0.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      name: "beacon",
      source_url: "https://nest.pijul.com/lthms/elixir-beacon",
      package: package(),
      test_coverage: [
        tool: ExCoveralls,
      ],
      preferred_cli_env: [
        "coveralls":        :test,
        "coveralls.detail": :test,
        "coveralls.post":   :test,
        "coveralls.html":   :test,
      ],
      deps: deps(),
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:credo,       "~> 0.4",  only: :dev,  runtime: false},
      {:dialyxir,    "~> 0.5",  only: :dev,  runtime: false},
      {:ex_doc,      "~> 0.15", only: :dev,  runtime: false},
      {:excoveralls, "~> 0.6",  only: :test, runtime: false},
    ]
  end

  defp description do
    """
    A Process that periodically reaches a target at a fixed interval.
    """
  end

  defp package do
    [
      name: :beacon,
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
      ],
      maintainers: [
        "Thomas Letan"
      ],
      licenses: [
        "GPL 3.0"
      ],
      links: %{
        "Nest" => "https://nest.pijul.com/lthms/elixir-beacon",
      },
    ]
  end
end

# Contributing

Thanks for your interest in Dungeon Explorer.

## Getting started

See the [README](README.md) **Developer Setup** section for prerequisites, `mix setup`, and how to run the app locally.

## Tests and formatting

Before opening a pull request:

```bash
mix format
mix test
```

For a fuller local check (format, Dialyzer, Credo, tests), you can run `./checks.sh` if you have those tools available.

## Proposing changes

- Open an issue to discuss larger features or design changes when it helps.
- Keep pull requests focused on one concern when possible.
- Match existing code style; `mix format` is the source of truth for Elixir formatting.

## License

By contributing, you agree your contributions will be licensed under the same terms as this project ([MIT](LICENSE)).

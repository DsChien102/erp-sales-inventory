# Declarative SQL sources for the partner schema
#
# New functions / views / triggers / policies for `partner` live here
# (one file per object). Edit the source, try with `melos run schema:apply-dev`,
# then a human runs `melos run migrate:generate -- <intent>` at promote time.
#
# Layout:
#   functions/<name>.sql
#   views/<name>.sql
#   triggers/<name>.sql
#   policies/<name>.sql
#
# Existing partner RPCs still owned by REGISTRY.yaml stay in timestamped
# migrations until adopt-on-touch (`melos run schema:adopt -- partner.<fn>`).
# See docs/architecture/14-declarative-sql-objects.md.

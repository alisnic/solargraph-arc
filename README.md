# README

This is an attempt for another approach for making Solargraph play well with
Rails. Features:
- autocomplete database columns by parsing db/schema.rb
- autocomplete of model relations

Main difference from https://github.com/iftheshoefritz/solargraph-rails are:
- parsing is done by piggy-backing on solargraph parsing logic. solargraph-rails does it with regular expressions
- solargraph-rails relies on special annotations for models for completing
database columns, which requires an additonal gem. This plugin just parses db/schema.rb

After all the rough edges are ironed out, I will attempt to upstream this approach in solargraph-rails

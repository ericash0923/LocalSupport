@vcr
Feature: Importing Organisations from Charity Commission
  As a technical administrator
  I would like to import organisations into the database
  So that they are kept up to date with latest charity commission records

  Scenario: Check Harrow Postcode
    Given I run the import organisation service for postcode "HA2"
    Then there should be 182 organisations stored
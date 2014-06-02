@routing @datastore
Feature: Temporary tests related to osrm-datastore

    Background:
        Given the profile "testbot"

    Scenario: A single way with two nodes
        Given the node map
            | a | b |

        And the ways
            | nodes |
            | ab    |

        When I route I should get
            | from | to | route |
            | a    | b  | ab    |
            | b    | a  | ab    |

    Scenario: A single way with two nodes
        Given the node map
            | x | y |

        And the ways
            | nodes |
            | xy    |

        When I route I should get
            | from | to | route |
            | x    | y  | xy    |
            | y    | x  | xy    |

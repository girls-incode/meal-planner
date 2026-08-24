
# Instructions
Clarify goals, constraints, and required inputs.
Apply relevant best practices and validate outcomes.
Provide actionable steps and verification.

# Is sytem Extendable ?
# Is system Scalable?
# Is the system Maintainable?
# Is Performant ?
# Is Secure ?

# Is there any anti-patterns for the system?
- Lack of Isolation
- Distributed Monoliths
- Internal Shared Libraries
- Data migration

# Are SOLID Software Design Principles applied ?

# Make sure to follow the 6 Core Software Architecture Principles

## Separation of Concerns
Each part of the system should handle one clear responsibility, so the design stays easier to understand and maintain.

## Don't repeat yourself (DRY)

## Encapsulation

## Dependency inversion

## Explicit dependencies

## Loose Coupling
System parts should depend on each other as little as possible, so one change does not create problems everywhere else.

## High Cohesion
Things that belong together should stay together, so each component has a clear purpose and remains easier to trust.

## Design for Change
Architecture should expect future changes, so new features or business needs do not break the whole system.

## Start with Quality Attributes
Performance, scalability, security, maintainability, and availability should guide architecture decisions from the beginning.

# Architecture decision
- Monolith or microservices ?
- Sync or async communication ?
- Central database or split data ownership
- Cloud-native or traditional hosting
- Build or integrate AI features ?
- Use Domain-Driven Design ?
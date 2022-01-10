infix operator ?= : AssignmentPrecedence
func ?=<T>(variable: inout Optional<T>, value: @autoclosure () -> T) {
    guard variable != nil else {
        return
    }
    variable = value()
}

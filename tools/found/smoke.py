"""Smoke test for a built wheel: the version carries the build suffix and CP-SAT solves."""
import ortools
from ortools.sat.python import cp_model

assert ortools.__version__.endswith("+found.1"), ortools.__version__
model = cp_model.CpModel()
x = [model.new_bool_var(f"x{i}") for i in range(5)]
gate = [model.new_bool_var(f"g{i}") for i in range(3)]
model.add_at_most_one(x).only_enforce_if(gate)
model.add(sum(x) + sum(gate) >= 4)
model.maximize(sum((i + 1) * v for i, v in enumerate(x)))
solver = cp_model.CpSolver()
solver.parameters.num_workers = 1
status = solver.solve(model)
assert status == cp_model.OPTIMAL, solver.status_name(status)
print("ortools", ortools.__version__, "objective", solver.objective_value)

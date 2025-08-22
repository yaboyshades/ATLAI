"""
FSM Edge Case Handling - Circuit Breaker for Mailbox Growth
Adds protection against rapid state transitions and mailbox overflow.
"""

from pathlib import Path


def add_circuit_breaker_to_fsm():
    """Add circuit breaker logic to states.py for mailbox protection."""

    file_path = Path("src/core/states.py")
    content = file_path.read_text(encoding="utf-8")

    # Add circuit breaker configuration at the top
    circuit_breaker_config = """
# Circuit Breaker Configuration for Mailbox Protection
MAILBOX_MAX_SIZE = 100  # Maximum mailbox size before circuit breaker trips
MAILBOX_WARNING_SIZE = 50  # Warning threshold
TRANSITION_RATE_LIMIT = 10  # Max transitions per second
CIRCUIT_BREAKER_TIMEOUT = 30  # Seconds to wait before reset
"""

    # Add circuit breaker state tracking
    circuit_breaker_state = """
@dataclass
class CircuitBreakerState:
    \"\"\"Circuit breaker state for mailbox protection.\"\"\"
    is_open: bool = False
    failure_count: int = 0
    last_failure_time: float = 0.0
    last_transition_time: float = 0.0
    transition_count: int = 0
    transition_window_start: float = 0.0
"""

    # Find the right place to insert - after imports
    import_section_end = content.find("from datetime import datetime")
    if import_section_end != -1:
        # Find the end of the import section
        next_line_start = content.find("\n", import_section_end)
        insertion_point = content.find("\n\n", next_line_start) + 2

        content = (
            content[:insertion_point]
            + circuit_breaker_config
            + circuit_breaker_state
            + content[insertion_point:]
        )

    # Add circuit breaker methods to StateMachine class
    circuit_breaker_methods = """
    def _check_circuit_breaker(self) -> bool:
        \"\"\"Check if circuit breaker should prevent transitions.\"\"\"
        current_time = time.time()

        # Check mailbox size
        if len(self.mailbox) > MAILBOX_MAX_SIZE:
            logger.warning(f"Circuit breaker: Mailbox size {len(self.mailbox)} exceeds limit {MAILBOX_MAX_SIZE}")
            self._trip_circuit_breaker("mailbox_overflow")
            return False

        # Check transition rate
        if current_time - self.circuit_breaker.transition_window_start >= 1.0:
            # Reset transition count every second
            self.circuit_breaker.transition_count = 0
            self.circuit_breaker.transition_window_start = current_time

        if self.circuit_breaker.transition_count >= TRANSITION_RATE_LIMIT:
            logger.warning(f"Circuit breaker: Transition rate {self.circuit_breaker.transition_count}/s exceeds limit")
            self._trip_circuit_breaker("rate_limit")
            return False

        # Check if circuit is open and timeout has passed
        if self.circuit_breaker.is_open:
            if current_time - self.circuit_breaker.last_failure_time > CIRCUIT_BREAKER_TIMEOUT:
                logger.info("Circuit breaker timeout expired, attempting reset")
                self._reset_circuit_breaker()
            else:
                logger.warning("Circuit breaker is open, blocking transition")
                return False

        return True

    def _trip_circuit_breaker(self, reason: str) -> None:
        \"\"\"Trip the circuit breaker.\"\"\"
        self.circuit_breaker.is_open = True
        self.circuit_breaker.failure_count += 1
        self.circuit_breaker.last_failure_time = time.time()

        # Emit metrics
        self.metrics_registry.increment_counter("sa_fsm_circuit_breaker_trips_total", {"reason": reason})
        self.metrics_registry.set_gauge("sa_fsm_circuit_breaker_open", 1.0)

        logger.error(f"Circuit breaker tripped: {reason} (failure count: {self.circuit_breaker.failure_count})")

    def _reset_circuit_breaker(self) -> None:
        \"\"\"Reset the circuit breaker.\"\"\"
        self.circuit_breaker.is_open = False
        self.circuit_breaker.failure_count = 0

        # Emit metrics
        self.metrics_registry.set_gauge("sa_fsm_circuit_breaker_open", 0.0)

        logger.info("Circuit breaker reset")

    def _update_transition_metrics(self) -> None:
        \"\"\"Update transition rate metrics.\"\"\"
        self.circuit_breaker.transition_count += 1
        self.circuit_breaker.last_transition_time = time.time()

        # Update mailbox pressure metric
        mailbox_pressure = len(self.mailbox) / MAILBOX_MAX_SIZE
        self.metrics_registry.set_gauge("sa_fsm_mailbox_pressure", mailbox_pressure)

        # Warning if approaching limits
        if len(self.mailbox) > MAILBOX_WARNING_SIZE:
            logger.warning(f"Mailbox size {len(self.mailbox)} approaching limit {MAILBOX_MAX_SIZE}")
"""

    # Find the StateMachine class and add the methods
    class_start = content.find("class StateMachine:")
    if class_start != -1:
        # Find a good place to insert - after __init__ method
        init_end = content.find("def transition(", class_start)
        if init_end != -1:
            content = (
                content[:init_end]
                + circuit_breaker_methods
                + "\n    "
                + content[init_end:]
            )

    # Modify the transition method to use circuit breaker
    transition_check = """        # Circuit breaker check
        if not self._check_circuit_breaker():
            logger.warning(f"Circuit breaker blocked transition from {self.current_state} on {trigger}")
            self.metrics_registry.increment_counter("sa_fsm_blocked_transitions_total")
            return

        self._update_transition_metrics()
"""

    # Find the transition method and add the check at the beginning
    transition_start = content.find("def transition(self, trigger: TransitionTrigger")
    if transition_start != -1:
        method_body_start = content.find(":", transition_start) + 1
        next_line = content.find("\n", method_body_start) + 1
        content = content[:next_line] + transition_check + content[next_line:]

    # Add import for time
    if "import time" not in content:
        content = content.replace("import asyncio", "import asyncio\nimport time")

    # Initialize circuit breaker in __init__
    init_addition = """        # Circuit breaker state
        self.circuit_breaker = CircuitBreakerState()
"""

    init_start = content.find("def __init__(self")
    if init_start != -1:
        init_end = content.find("def ", init_start + 10)  # Find next method
        if init_end == -1:
            init_end = len(content)

        # Add before the end of __init__
        last_line_of_init = content.rfind("\n", init_start, init_end - 20)
        content = (
            content[:last_line_of_init] + init_addition + content[last_line_of_init:]
        )

    file_path.write_text(content, encoding="utf-8")
    print("✅ Circuit breaker protection added to FSM!")


if __name__ == "__main__":
    print("🔧 Adding FSM Circuit Breaker Protection")
    print("=" * 50)
    add_circuit_breaker_to_fsm()
    print("✅ FSM edge case handling complete!")

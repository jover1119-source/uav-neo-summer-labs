"""
MIT BWSI Autonomous Drone Racing Course - UAV Neo
GNU General Public License v3.0

This is a CONCEPT lab — it does not need the simulator.
Fill in the functions below, then run it directly:
    python3 coordinate_frames.py
It prints PASS/FAIL for each part's self-check.

A completed reference lives in ../solutions/coordinate_frames.py
"""

import numpy as np


# ── Part A: Euler angles -> rotation matrix ─────────────────────────────────────────
def euler_to_rot(roll, pitch, yaw):
    """
    Build a body->world rotation matrix from Euler angles (radians) using the
    aerospace ZYX convention. See the README (Key terms) for the convention.
    """
    ##################################
    #### START PUT CODE HERE #########

    Rz = np.array([[np.cos(yaw), -np.sin(yaw), 0],
                   [np.sin(yaw), np.cos(yaw), 0],
                   [0, 0, 1]])
    Rx = np.array([[1, 0, 0],
                   [0, np.cos(roll), -np.sin(roll)],
                   [0, np.sin(roll), np.cos(roll)]])
    Ry = np.array([[np.cos(pitch), -np.sin(pitch), 0],
                   [np.sin(pitch), np.cos(pitch), 0],
                   [0, 0, 1]])
    rot_matrix = Rz @ Rx @ Ry

    ###### END PUT CODE HERE #########
    ##################################
    return rot_matrix


# ── Part A: rotation matrix -> quaternion ───────────────────────────────────────────
def rot_to_quat(rot_matrix):
    """
    Convert a 3x3 rotation matrix to a quaternion (scalar-last: x, y, z, w) using the
    standard trace method. See the README (Key terms) for the quaternion background.
    """
    ##################################
    #### START PUT CODE HERE #########

    trace = np.trace(rot_matrix)

    if trace > 0:
        s = 2.0 * np.sqrt(trace + 1.0)   
        w = 0.25 * s
        x = (rot_matrix[2,1] - rot_matrix[1,2]) / s
        y = (rot_matrix[0,2] - rot_matrix[2,0]) / s
        z = (rot_matrix[1,0] - rot_matrix[0,1]) / s
    else:
        if rot_matrix[0,0] > rot_matrix[1,1] and rot_matrix[0,0] > rot_matrix[2,2]:
            s = 2 * np.sqrt(1 + rot_matrix[0,0] - rot_matrix[1,1] - rot_matrix[2,2])
            x = 0.25 * s
            y = (rot_matrix[0,1] + rot_matrix[1,0]) / s
            z = (rot_matrix[0,2] + rot_matrix[2,0]) / s
            w = (rot_matrix[2,1] - rot_matrix[1,2]) / s
        elif rot_matrix[1,1] > rot_matrix[0,0] and rot_matrix[1,1] > rot_matrix[2,2]:
            s = 2 * np.sqrt(1 + rot_matrix[1,1] - rot_matrix[0,0] - rot_matrix[2,2])
            y = 0.25 * s
            x = (rot_matrix[0,1] + rot_matrix[1,0]) / s
            w = (rot_matrix[0,2] - rot_matrix[2,0]) / s
            z = (rot_matrix[2,1] + rot_matrix[1,2]) / s
        elif rot_matrix[2,2] > rot_matrix[0,0] and rot_matrix[2,2] > rot_matrix[1,1]:
            s = 2 * np.sqrt(1 + rot_matrix[2,2] - rot_matrix[0,0] - rot_matrix[1,1])
            z = 0.25 * s
            w = (rot_matrix[0,1] - rot_matrix[1,0]) / s
            x = (rot_matrix[0,2] + rot_matrix[2,0]) / s
            y = (rot_matrix[2,1] + rot_matrix[1,2]) / s
    
    ###### END PUT CODE HERE #########
    ##################################
    return np.array([x, y, z, w])


# ── Part 0: static frame transform (ENU <-> NED) ────────────────────────────────────
def enu_to_ned(vec):
    """
    Convert a vector from ENU (East, North, Up) to NED (North, East, Down).
    See the README (Key terms) for how the two conventions relate.
    """
    e, n, u = vec
    ##################################
    #### START PUT CODE HERE #########

    result = np.array([n, e, -u])  # YOUR CODE HERE

    ###### END PUT CODE HERE #########
    ##################################
    return result


# ── Part B: point-mass thrust sizing ────────────────────────────────────────────────
def thrust_allocation(mass, k_f, total_thrust):
    """
    Split a total thrust evenly across 4 rotors and solve for rotor speed, given the
    thrust model thrust_per_motor = k_f * omega**2. Returns: (omega, thrust_per_motor).
    """
    ##################################
    #### START PUT CODE HERE #########

    per_rotor = total_thrust / 4
    omega = np.sqrt(per_rotor / k_f)

    ###### END PUT CODE HERE #########
    ##################################
    return omega, per_rotor


def hover_thrust(mass, g=9.81):
    """Total thrust (N) needed to hover (see README, Key terms)."""
    ##################################
    #### START PUT CODE HERE #########

    gravitational_force = mass * g

    return gravitational_force  # YOUR CODE HERE
    ###### END PUT CODE HERE #########
    ##################################


# ── Self-check ──────────────────────────────────────────────────────────────────────
def _check():
    passed = total = 0

    def ok(name, cond, detail=""):
        nonlocal passed, total
        total += 1
        passed += bool(cond)
        print(f"  [{'PASS' if cond else 'FAIL'}] {name} {detail}")

    R0 = euler_to_rot(0, 0, 0)
    ok("euler_to_rot identity", np.allclose(R0, np.eye(3)))
    R = euler_to_rot(0.3, -0.2, 1.0)
    ok("rotation is orthonormal", np.allclose(R.T @ R, np.eye(3)) and
       np.isclose(np.linalg.det(R), 1.0))
    Ryaw = euler_to_rot(0, 0, np.pi / 2)
    ok("90deg yaw maps x->y", np.allclose(Ryaw @ np.array([1, 0, 0]),
                                          [0, 1, 0], atol=1e-9))
    q = rot_to_quat(np.eye(3))
    ok("rot_to_quat identity -> (0,0,0,1)", np.allclose(q, [0, 0, 0, 1]))
    ok("enu_to_ned", np.allclose(enu_to_ned([1, 2, 3]), [2, 1, -3]))
    omega, per = thrust_allocation(1.0, 1.0, 4.0)
    ok("thrust_allocation", np.isclose(per, 1.0) and np.isclose(omega, 1.0),
       f"(omega={omega:.3f}, per={per:.3f})")
    ok("hover_thrust", np.isclose(hover_thrust(2.0, 9.81), 19.62))

    print(f"\n{passed}/{total} checks passed.")
    return passed == total


if __name__ == "__main__":
    print("Week 3 · Module 1 — Coordinate Frames & Dynamics\n")
    _check()

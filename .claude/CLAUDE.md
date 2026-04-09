# Design Lab Agentic Setup
Read @README.md for Design Lab context.

## Commands
The user can request the agent to spec `chore` and `feature` developement. `implement` executes the developement.

## Environment
Design Lab runs inside a Docker devcontainer with NVIDIA GPU support.

### Python Environment
- **Python interpreter**: `/opt/ilab/bin/python` (Python 3.11 virtual environment)
- **Package manager**: `uv` (fast Python package manager)
- Isaac Lab and Design Lab are installed in **editable mode**

### Key Paths
- **Workspace**: `/isaaclab_manager/resources/IsaacLab/source/design_lab`
- **Isaac Lab**: `/isaaclab_manager/resources/IsaacLab`
- **Virtual env**: `/opt/ilab`
- **Isaac Sim**: `/opt/ilab/lib/python3.11/site-packages/isaacsim`

### Running Code
```bash
# Run Python scripts
python scripts/path/to/script.py

# Run with Isaac Sim (headless)
python scripts/path/to/script.py --headless
```

Isaac can produce a lot of terminal output. To filter for important messages, use:

```bash
python executable.py 2>&1 | grep -E "(LoadViz|INFO|Error|error|Exception|Traceback)" | head -40
```

This command shows only lines with keywords like LoadViz, INFO, Error, Exception, or Traceback from the first 40 lines of output.

### Isaac Sim Shutdown
Isaac Sim hangs on shutdown due to physics extension cleanup deadlocks. Always use this pattern:
```python
from design_lab.app.minimalist import startup
app = startup("dlab.python.physics.kit", headless=True, create_new_stage=True)
# Import isaaclab modules AFTER startup
import isaaclab.sim as sim_utils
# ... do work ...
app.close(skip_cleanup=True, wait_for_replicator=False)
os._exit(0)  # Required - force exit
```

### Shell Aliases (inside container)
- `workbench` - CLI for robot model generation
- `mujoco` - Opens MuJoCo viewer
- `isaac` - Launches Isaac Sim
- `claude` - Starts Claude Code

### Environment Variables
- `ISAACLAB_PATH=/isaaclab_manager/resources/IsaacLab`
- `ISAAC_PATH=/opt/ilab/lib/python3.11/site-packages/isaacsim`
- Additional env vars loaded from `.env` file

### GPU Requirements
- NVIDIA driver 580+ required
- Container uses `--runtime=nvidia` with full GPU access

### Installing Packages
```bash
uv pip install <package>
```

## Plugins

Design Lab supports plugins for auxiliary tools.

### Installation

```bash
# First time setup (clones external repos, creates symlinks, installs gcloud)
python scripts/setup_plugins.py

# For GCP features, authenticate:
gcloud auth login
gcloud config set project composite-snow-468715-f2
gcloud auth configure-docker
```

### log_app Plugin

Dashboard for simulation log visualization and cloud deployment.

**CLI Usage:**
```bash
python plugin/log_app/scripts/logapp.py --help
python plugin/log_app/scripts/logapp.py gcp check           # Verify GCP setup
python plugin/log_app/scripts/logapp.py run                 # Local dashboard
python plugin/log_app/scripts/logapp.py docker build        # Build container
python plugin/log_app/scripts/logapp.py docker test --robot <name>  # Test locally
python plugin/log_app/scripts/logapp.py data upload --robot <name>  # Upload to GCS
python plugin/log_app/scripts/logapp.py data upload --robot <name> --delete  # Clean sync
python plugin/log_app/scripts/logapp.py deploy --robot <name>       # Deploy to Cloud Run
python plugin/log_app/scripts/logapp.py list                # List deployments
python plugin/log_app/scripts/logapp.py logs --robot <name> # View logs
```

**Docs:** `plugin/log_app/README.md`

## Isaac Lab Reference (Read-Only)
Isaac Lab source code is at `/isaaclab_manager/resources/IsaacLab/source/isaaclab/`. This code should NOT be edited - it is upstream library code.

### Key Files
- **Articulation**: `/isaaclab_manager/resources/IsaacLab/source/isaaclab/isaaclab/assets/articulation/articulation.py`
  - Core class for articulated robots (rigid bodies connected by joints)
  - Handles actuator models, joint commands, and simulation stepping
  - Supports floating-base and fixed-base systems

- **Actuator PD**: `/isaaclab_manager/resources/IsaacLab/source/isaaclab/isaaclab/actuators/actuator_pd.py`
  - PD actuator models: `ImplicitActuator`, `IdealPDActuator`, `DCMotor`, `DelayedPDActuator`
  - Implicit actuators let PhysX handle PD control (more accurate at large timesteps)
  - Explicit actuators compute torques directly

### Isaac Lab Module Structure
```
isaaclab/
  assets/         # Robot and object asset classes
    articulation/ # Articulation (robot) handling
  actuators/      # Actuator models (PD, DC motor, etc.)
  envs/           # RL environment base classes
  managers/       # Action, observation, reward managers
  sim/            # Simulation utilities
  utils/          # Math, string, and general utilities
```

## IsaacSim Physics Tensors API (Read-Only)
Low-level PhysX tensor API for batched physics operations. This is a LARGE file (~6000+ lines) - load only the sections you need.

**File**: `/opt/ilab/lib/python3.11/site-packages/isaacsim/extscache/omni.physics.tensors-107.3.26+107.3.3.lx64.r.cp311.u353/omni/physics/tensors/impl/api.py`

### Class Line Ranges (use offset/limit when reading)
| Class | Lines | Description |
|-------|-------|-------------|
| `SimulationView` | 84-628 | Entry point; creates views for physics objects |
| `ArticulationView` | 629-3295 | **Most important** - batched articulation (robot) operations |
| `RigidBodyView` | 3296-4163 | Batched rigid body operations |
| `SoftBodyView` | 4164-4747 | Soft body simulation |
| `DeformableBodyView` | 5077-5506 | Deformable body simulation |
| `RigidContactView` | 5727-6049 | Contact force queries |
| `ParticleSystemView` | 6149-6239 | Particle systems |

### Key ArticulationView Methods (lines 629-3295)
```python
# State getters
get_dof_positions()          # Joint positions
get_dof_velocities()         # Joint velocities
get_root_transforms()        # Base pose (floating-base)
get_root_velocities()        # Base velocity
get_link_transforms()        # All link poses

# State setters
set_dof_positions(data, indices)
set_dof_velocities(data, indices)
set_root_transforms(data, indices)

# Control
set_dof_actuation_forces(data, indices)   # Apply torques
set_dof_position_targets(data, indices)   # PD position targets
set_dof_velocity_targets(data, indices)   # PD velocity targets

# Dynamics
get_jacobians()                           # Link Jacobians
get_generalized_mass_matrices()           # Mass matrix
get_coriolis_and_centrifugal_forces()     # C(q,dq)
get_generalized_gravity_forces()          # G(q)
get_dof_projected_joint_forces()          # Measured joint forces

# Properties
get_dof_stiffnesses() / set_dof_stiffnesses()
get_dof_dampings() / set_dof_dampings()
get_masses() / get_inertias()
```

### Usage Pattern
```python
import omni.physics.tensors as tensors
sim_view = tensors.create_simulation_view("torch")
art_view = sim_view.create_articulation_view("/World/Robot_*")

# Get joint positions for all robots
positions = art_view.get_dof_positions()  # shape: (num_robots, num_dofs)
```

## play.py
Primary script for playing trained RL policies. Uses vault for automatic policy/output routing.

```bash
python scripts/play.py --task a3-dlab-play-v0 --robot apollo3_model --video --log --headless
```

Key flags:
- `--task` / `--robot`: Required. Vault auto-loads policy from `.vault/{robot}/tasks/{task}/model.pt`
- `--video` / `--log`: Enable video recording and CSV data logging
- `--video_length N`: Run N steps then exit (default: 200)
- `--load_viz`: Visualize joint loads with 3D arrows (requires GUI)
- `--checkpoint`: Override vault policy with explicit path

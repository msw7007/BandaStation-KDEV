// CYBERPUNK BUILD - rebuild and delete before release
import { Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type MachineModule = {
  id: string;
  name: string;
  description: string;
  manufacturer: string;
  type: string;
  power_usage_multiplier: number;
  wear_multiplier: number;
  tool_time_multiplier: number;
  repair_multiplier: number;
  salvage_multiplier: number;
  integrity_bonus: number;
  chem_speed_multiplier: number;
  chem_cost_multiplier: number;
  vending_stock_multiplier: number;
  apc_efficiency_multiplier: number;
};

type MachineComponent = {
  index: number;
  name: string;
  type: string;
  wear: number;
  wear_limit: number;
};

type MachineData = {
  name: string;
  type: string;
  panel_open: boolean;
  wear: number;
  wear_limit: number;
  wear_rate_multiplier: number;
  failure_state: string;
  module_slots: number;
  module_count: number;
  power_multiplier: number;
  wear_multiplier: number;
  tool_time_multiplier: number;
  repair_multiplier: number;
  salvage_multiplier: number;
  chem_speed_multiplier: number;
  chem_cost_multiplier: number;
  vending_stock_multiplier: number;
  apc_efficiency_multiplier: number;
  service_tool_ready: boolean;
};

type CyberpunkMachineModulesData = {
  machine: MachineData;
  installed_modules: MachineModule[];
  catalog: MachineModule[];
  components: MachineComponent[];
  held_module?: MachineModule | null;
};

const cy = {
  red: '#ff334a',
  redDark: '#4a0b13',
  cyan: '#18d8ff',
  text: '#d7e7ee',
  muted: '#78909a',
  green: '#42d77d',
};

const ModuleStats = (props: { module: MachineModule }) => {
  const module = props.module;
  const stats: string[] = [];
  if (module.power_usage_multiplier !== 1) {
    stats.push(`power x${module.power_usage_multiplier}`);
  }
  if (module.wear_multiplier !== 1) {
    stats.push(`wear x${module.wear_multiplier}`);
  }
  if (module.tool_time_multiplier !== 1) {
    stats.push(`work x${module.tool_time_multiplier}`);
  }
  if (module.repair_multiplier !== 1) {
    stats.push(`repair x${module.repair_multiplier}`);
  }
  if (module.salvage_multiplier !== 1) {
    stats.push(`salvage x${module.salvage_multiplier}`);
  }
  if (module.integrity_bonus) {
    stats.push(`integrity +${module.integrity_bonus}`);
  }
  if (module.chem_speed_multiplier !== 1) {
    stats.push(`chem speed x${module.chem_speed_multiplier}`);
  }
  if (module.chem_cost_multiplier !== 1) {
    stats.push(`chem cost x${module.chem_cost_multiplier}`);
  }
  if (module.vending_stock_multiplier !== 1) {
    stats.push(`vending stock x${module.vending_stock_multiplier}`);
  }
  if (module.apc_efficiency_multiplier !== 1) {
    stats.push(`APC efficiency x${module.apc_efficiency_multiplier}`);
  }
  return (
    <div className="CyberpunkPanel__Title CyberpunkPanel__Small">
      {stats.length ? stats.join(' | ') : 'no modifiers'}
    </div>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release

const WearBar = (props: { value: number; max: number }) => {
  const pct = props.max
    ? Math.min(100, Math.round((props.value / props.max) * 100))
    : 0;
  return (
    <div className="CyberpunkPanel__WearBar">
      <div
        className="CyberpunkPanel__WearBarFill"
        style={{
          width: `${pct}%`,
          background: pct >= 75 ? cy.red : pct >= 40 ? '#d7b22e' : cy.cyan,
        }}
      />
    </div>
  );
};

export const CyberpunkMachineModules = () => {
  const { act, data } = useBackend<CyberpunkMachineModulesData>();
  const machine = data.machine || {
    name: 'machine',
    type: '',
    panel_open: false,
    wear: 0,
    wear_limit: 100,
    wear_rate_multiplier: 0.05,
    failure_state: 'none',
    module_slots: 0,
    module_count: 0,
    power_multiplier: 1,
    wear_multiplier: 1,
    tool_time_multiplier: 1,
    repair_multiplier: 1,
    salvage_multiplier: 1,
    chem_speed_multiplier: 1,
    chem_cost_multiplier: 1,
    vending_stock_multiplier: 1,
    apc_efficiency_multiplier: 1,
    service_tool_ready: false,
  };
  const installed = data.installed_modules || [];
  const catalog = data.catalog || [];
  const components = data.components || [];
  const heldModule = data.held_module;
  const moduleSlotsFull = machine.module_count >= machine.module_slots;

  return (
    <Window title="Machine modules" width={920} height={620}>
      <Window.Content className="CyberpunkPanel">
        <Stack fill>
          <Stack.Item width="34%">
            <Section title="MACHINE">
              <div className="CyberpunkPanel__Title">{machine.name}</div>
              <div className="CyberpunkPanel__Muted CyberpunkPanel__Small">
                {machine.type}
              </div>
              <Stack mt={1}>
                <Stack.Item grow className="CyberpunkPanel__Metric">
                  PANEL
                  <br />
                  <b style={{ color: machine.panel_open ? cy.green : cy.red }}>
                    {machine.panel_open ? 'open' : 'closed'}
                  </b>
                </Stack.Item>
                <Stack.Item grow className="CyberpunkPanel__Metric">
                  MODULES
                  <br />
                  <b style={{ color: cy.cyan }}>
                    {machine.module_count}/{machine.module_slots}
                  </b>
                </Stack.Item>
              </Stack>
              <Stack mt={1}>
                <Stack.Item grow className="CyberpunkPanel__Metric">
                  WEAR
                  <br />
                  <b style={{ color: cy.cyan }}>
                    {machine.wear}/{machine.wear_limit}
                  </b>
                </Stack.Item>
                <Stack.Item grow className="CyberpunkPanel__Metric">
                  POWER
                  <br />
                  <b style={{ color: cy.cyan }}>x{machine.power_multiplier}</b>
                </Stack.Item>
              </Stack>
              <Stack mt={1}>
                <Stack.Item grow className="CyberpunkPanel__Metric">
                  FAILURE
                  <br />
                  <b
                    style={{
                      color:
                        machine.failure_state === 'none' ? cy.green : cy.red,
                    }}
                  >
                    {machine.failure_state}
                  </b>
                </Stack.Item>
                <Stack.Item grow className="CyberpunkPanel__Metric">
                  WEAR RATE
                  <br />
                  <b style={{ color: cy.cyan }}>
                    x{machine.wear_rate_multiplier}
                  </b>
                </Stack.Item>
              </Stack>
              <div className="CyberpunkPanel__Muted">
                Work x{machine.tool_time_multiplier} | wear x
                {machine.wear_multiplier} | repair x{machine.repair_multiplier}{' '}
                | salvage x{machine.salvage_multiplier}
              </div>
            </Section>
            <Section title="INSTALLED MODULES">
              {!installed.length && (
                <div className="CyberpunkPanel__Muted">
                  No modules installed.
                </div>
              )}
              {installed.map((module) => (
                <div
                  key={module.id}
                  className="CyberpunkPanel__Card"
                >
                  <Stack align="center">
                    <Stack.Item grow>
                      <b className="CyberpunkPanel__Title">{module.name}</b>
                      <div className="CyberpunkPanel__Muted">
                        {module.description}
                      </div>
                      <div className="CyberpunkPanel__Muted CyberpunkPanel__Small">
                        Produced by {module.manufacturer}
                      </div>
                      <ModuleStats module={module} />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="red"
                        disabled={!machine.panel_open}
                        onClick={() =>
                          act('remove_module', { module_id: module.id })
                        }
                      >
                        Remove
                      </Button>
                    </Stack.Item>
                  </Stack>
                </div>
              ))}
            </Section>
            <Section title="HELD MODULE">
              {heldModule ? (
                <Stack align="center">
                  <Stack.Item grow>
                    <b className="CyberpunkPanel__Title">{heldModule.name}</b>
                    <div className="CyberpunkPanel__Muted">
                      {heldModule.description}
                    </div>
                    <div className="CyberpunkPanel__Muted CyberpunkPanel__Small">
                      Produced by {heldModule.manufacturer}
                    </div>
                    <ModuleStats module={heldModule} />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color="green"
                      disabled={!machine.panel_open || moduleSlotsFull}
                      onClick={() => act('install_held')}
                    >
                      Install
                    </Button>
                  </Stack.Item>
                </Stack>
              ) : (
                <div className="CyberpunkPanel__Muted">
                  Hold a Рязнов module produced on an engineering protolathe.
                </div>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item width="33%">
            <Section title="RYAZNOV MODULE CATALOG" fill>
              <div className="CyberpunkPanel__Scroll">
                {catalog.map((module) => (
                  <div
                    key={module.id}
                    className="CyberpunkPanel__Card CyberpunkPanel__Card--red"
                  >
                    <b className="CyberpunkPanel__Title">{module.name}</b>
                    <div className="CyberpunkPanel__Muted">
                      {module.description}
                    </div>
                    <div className="CyberpunkPanel__Muted CyberpunkPanel__Small">
                      Produced by {module.manufacturer}
                    </div>
                    <ModuleStats module={module} />
                  </div>
                ))}
              </div>
            </Section>
          </Stack.Item>
          <Stack.Item width="33%">
            <Section title="COMPONENT WEAR" fill>
              <div className="CyberpunkPanel__Scroll">
                {!components.length && (
                  <div className="CyberpunkPanel__Muted">
                    This machine has no exposed component list.
                  </div>
                )}
                {components.map((component) => (
                  <div
                    key={component.index}
                    className={`CyberpunkPanel__Card ${
                      component.wear ? '' : 'CyberpunkPanel__Card--red'
                    }`}
                  >
                    <Stack align="center">
                      <Stack.Item grow>
                        <b className="CyberpunkPanel__Title">
                          {component.name}
                        </b>
                        <div className="CyberpunkPanel__Muted CyberpunkPanel__Small">
                          {component.type}
                        </div>
                        <WearBar
                          value={component.wear}
                          max={component.wear_limit}
                        />
                        <div>
                          Wear: {component.wear}/{component.wear_limit}
                        </div>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          disabled={
                            !component.wear ||
                            !machine.panel_open ||
                            !machine.service_tool_ready
                          }
                          onClick={() =>
                            act('repair_component', {
                              component_index: component.index,
                            })
                          }
                        >
                          Service
                        </Button>
                      </Stack.Item>
                    </Stack>
                  </div>
                ))}
              </div>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

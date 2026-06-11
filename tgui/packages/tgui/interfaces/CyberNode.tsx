import { useState } from 'react';

import { Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CyberNodeObject = {
  index: number;
  name: string;
  type: string;
  category: string;
  status: string;
  has_ui: boolean;
  critical_ice: boolean;
  functions: string[];
};

type CyberNodeData = {
  node_name: string;
  area: string;
  objects_count: number;
  net_data: number;
  extracted: boolean;
  has_access: boolean;
  connected: boolean;
  can_ice: boolean;
  combat_mode: boolean;
  protection_integrity: number;
  permissions: {
    open_ui: boolean;
    emag_activate: boolean;
    emp_activate: boolean;
    shutdown: boolean;
    settings: boolean;
    door_toggle: boolean;
    bolt_toggle: boolean;
    electrify_toggle: boolean;
    camera_inspect: boolean;
    camera_rotate: boolean;
    panel_toggle: boolean;
    power_toggle: boolean;
    contraband_toggle: boolean;
    apc_breaker_toggle: boolean;
    apc_nightshift_toggle: boolean;
    turret_power_toggle: boolean;
    turret_lethal_toggle: boolean;
    turret_silicon_toggle: boolean;
    light_toggle: boolean;
    device_toggle: boolean;
  };
  protection: {
    reserve: number;
    max_reserve: number;
    breached: boolean;
    alarm: boolean;
  };
  objects: CyberNodeObject[];
};

const cy = {
  bg: '#05080d',
  panel: '#0b141a',
  panelSoft: '#101b22',
  red: '#ff334a',
  redDark: '#4a0b13',
  cyan: '#18d8ff',
  cyanSoft: '#0b5f73',
  text: '#d7e7ee',
  muted: '#78909a',
  green: '#49e37b',
};

const cyberButtonStyle = (danger = false, disabled = false) => ({
  width: '100%',
  marginBottom: '6px',
  padding: '7px 9px',
  border: `1px solid ${
    disabled ? 'rgba(120, 144, 154, 0.22)' : danger ? cy.red : cy.cyan
  }`,
  background: disabled
    ? 'rgba(16, 27, 34, 0.45)'
    : danger
      ? 'rgba(74, 11, 19, 0.55)'
      : 'rgba(11, 95, 115, 0.22)',
  color: disabled ? cy.muted : danger ? cy.red : cy.cyan,
  cursor: disabled ? 'default' : 'pointer',
  fontWeight: 700,
  textAlign: 'left' as const,
});

export const CyberNode = () => {
  const { act, data } = useBackend<CyberNodeData>();
  const [selectedIndex, setSelectedIndex] = useState(1);
  const objects = data.objects || [];
  const selectedObject =
    objects.find((object) => object.index === selectedIndex) || objects[0];
  const targetIndex = selectedObject?.index;
  const hasTarget = !!selectedObject;
  const permissions = data.permissions || {
    open_ui: false,
    emag_activate: false,
    emp_activate: false,
    shutdown: false,
    settings: false,
    door_toggle: false,
    bolt_toggle: false,
    electrify_toggle: false,
    camera_inspect: false,
    camera_rotate: false,
    panel_toggle: false,
    power_toggle: false,
    contraband_toggle: false,
    apc_breaker_toggle: false,
    apc_nightshift_toggle: false,
    turret_power_toggle: false,
    turret_lethal_toggle: false,
    turret_silicon_toggle: false,
    light_toggle: false,
    device_toggle: false,
  };
  const hasFunction = (functionId: string) =>
    !!selectedObject?.functions?.includes(functionId);
  const canShowAction = (functionId: string) => hasTarget && hasFunction(functionId);

  return (
    <Window title="Cyberspace node" width={860} height={600}>
      <Window.Content style={{ background: cy.bg, color: cy.text }}>
        <Stack fill>
          <Stack.Item width="45%">
            <Section
              title="NODE CONTENTS"
              buttons={
                <Button
                  icon="rotate"
                  color="transparent"
                  onClick={() => act('refresh')}
                >
                  Refresh
                </Button>
              }
              style={{
                height: '100%',
                background: cy.panel,
                border: `1px solid ${cy.redDark}`,
              }}
            >
              <div
                style={{
                  marginBottom: '8px',
                  padding: '8px',
                  border: `1px solid ${cy.cyanSoft}`,
                  background: 'rgba(5, 8, 13, 0.65)',
                }}
              >
                <div style={{ color: cy.cyan, fontWeight: 800 }}>
                  {data.node_name || 'node'}
                </div>
                <div style={{ color: cy.muted }}>{data.area || 'Unknown area'}</div>
              </div>

              <div
                style={{
                  maxHeight: '455px',
                  overflowY: 'auto',
                  paddingRight: '4px',
                }}
              >
                {objects.length ? (
                  objects.map((object) => {
                    const selected = object.index === selectedObject?.index;
                    return (
                      <button
                        key={object.index}
                        onClick={() => setSelectedIndex(object.index)}
                        style={{
                          position: 'relative',
                          width: '100%',
                          minHeight: '58px',
                          marginBottom: '6px',
                          padding: '8px 62px 8px 8px',
                          border: `1px solid ${selected ? cy.cyan : cy.redDark}`,
                          background: selected
                            ? 'rgba(24, 216, 255, 0.14)'
                            : 'rgba(16, 27, 34, 0.55)',
                          color: cy.text,
                          cursor: 'pointer',
                          textAlign: 'left',
                          overflow: 'hidden',
                        }}
                      >
                        <div
                          style={{
                            display: 'grid',
                            gridTemplateColumns: '52px minmax(0, 1fr)',
                            gap: '8px',
                            alignItems: 'center',
                          }}
                        >
                          <div>
                            <div
                              style={{
                                border: `1px solid ${cy.cyanSoft}`,
                                color: cy.cyan,
                                fontSize: '10px',
                                fontWeight: 800,
                                padding: '4px',
                                textAlign: 'center',
                                textTransform: 'uppercase',
                              }}
                            >
                              {object.category}
                            </div>
                          </div>
                          <div style={{ minWidth: 0 }}>
                            <div
                              style={{
                                color: selected ? cy.cyan : cy.text,
                                fontWeight: 800,
                                overflow: 'hidden',
                                textOverflow: 'ellipsis',
                                whiteSpace: 'nowrap',
                              }}
                            >
                              {object.name}
                            </div>
                            <div
                              style={{
                                color: cy.muted,
                                fontFamily: 'monospace',
                                fontSize: '11px',
                                overflow: 'hidden',
                                textOverflow: 'ellipsis',
                                whiteSpace: 'nowrap',
                              }}
                            >
                              {object.type}
                            </div>
                          </div>
                        </div>
                        <div
                          style={{
                            position: 'absolute',
                            right: '8px',
                            top: '50%',
                            maxWidth: '50px',
                            transform: 'translateY(-50%)',
                            color:
                              object.status === 'online' ||
                              object.status === 'active'
                                ? cy.green
                                : cy.red,
                            fontSize: '10px',
                            fontWeight: 800,
                            textAlign: 'right',
                            textTransform: 'uppercase',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          {object.status}
                        </div>
                      </button>
                    );
                  })
                ) : (
                  <div style={{ color: cy.muted, padding: '12px' }}>
                    No linked objects are currently available.
                  </div>
                )}
              </div>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section
              title="NODE ACCESS"
              style={{
                background: cy.panel,
                border: `1px solid ${cy.redDark}`,
              }}
            >
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: '6px',
                  marginBottom: '10px',
                }}
              >
                <NodeMetric label="Objects" value={data.objects_count} />
                <NodeMetric
                  label="Access"
                  value={data.has_access ? 'granted' : 'locked'}
                  color={data.has_access ? cy.green : cy.red}
                />
                <NodeMetric
                  label="Protection"
                  value={`${data.protection?.reserve || 0}/${
                    data.protection?.max_reserve || 0
                  }`}
                />
                <NodeMetric
                  label="Integrity"
                  value={`${data.protection_integrity || 0}%`}
                  color={(data.protection_integrity || 0) <= 10 ? cy.red : cy.cyan}
                />
                <NodeMetric
                  label="Alarm"
                  value={data.protection?.alarm ? 'triggered' : 'clear'}
                  color={data.protection?.alarm ? cy.red : cy.cyan}
                />
                <NodeMetric
                  label="Connection"
                  value={data.connected ? 'linked' : 'none'}
                  color={data.connected ? cy.green : cy.muted}
                />
                <NodeMetric
                  label="Net-data"
                  value={data.extracted ? 'extracted' : data.net_data}
                  color={data.extracted ? cy.muted : cy.cyan}
                />
              </div>

              <Stack>
                <Stack.Item grow>
                  <button
                    style={cyberButtonStyle(false, data.connected)}
                    disabled={data.connected}
                    onClick={() => act('connect')}
                  >
                    RMB: connect to node
                  </button>
                </Stack.Item>
                <Stack.Item grow>
                  <button
                    style={cyberButtonStyle(false, !data.connected)}
                    disabled={!data.connected}
                    onClick={() => act('extract')}
                  >
                    RMB: extract net-data
                  </button>
                </Stack.Item>
              </Stack>
              <button
                style={cyberButtonStyle(true, data.has_access)}
                disabled={data.has_access}
                onClick={() => act('attack')}
              >
                LMB combat: direct attack
              </button>
              <button
                style={cyberButtonStyle(false, !data.can_ice || data.has_access)}
                disabled={!data.can_ice || data.has_access}
                onClick={() => act('ice')}
              >
                ICE breach: neural / server
              </button>
            </Section>

            <Section
              title="SELECTED OBJECT"
              style={{
                background: cy.panel,
                border: `1px solid ${cy.redDark}`,
              }}
            >
              {selectedObject ? (
                <>
                  <div
                    style={{
                      marginBottom: '8px',
                      padding: '8px',
                      border: `1px solid ${cy.cyanSoft}`,
                      background: cy.panelSoft,
                    }}
                  >
                    <div style={{ color: cy.cyan, fontWeight: 800 }}>
                      {selectedObject.name}
                    </div>
                    <div
                      style={{
                        color: cy.muted,
                        fontFamily: 'monospace',
                        fontSize: '11px',
                      }}
                    >
                      {selectedObject.type}
                    </div>
                    <div style={{ marginTop: '5px' }}>
                      <span style={{ color: cy.muted }}>Functions: </span>
                      <span style={{ color: cy.text }}>
                        {selectedObject.functions?.join(', ') || 'inspect only'}
                      </span>
                    </div>
                    {selectedObject.critical_ice && (
                      <div style={{ color: cy.red, marginTop: '5px' }}>
                        Critical ICE endpoint. Use ICE breach for full intrusion.
                      </div>
                    )}
                  </div>
                  {canShowAction('interface') && (
                    <Button
                      fluid
                      color="transparent"
                      style={cyberButtonStyle(
                        false,
                        !selectedObject.has_ui || !permissions.open_ui,
                      )}
                      disabled={!selectedObject.has_ui || !permissions.open_ui}
                      onClick={() => act('open_ui', { target_index: targetIndex })}
                    >
                      open_ui(target) - key / 0%
                    </Button>
                  )}
                  {canShowAction('shutdown') && (
                    <Button
                      fluid
                      color="transparent"
                      style={cyberButtonStyle(true, !permissions.shutdown)}
                      disabled={!permissions.shutdown}
                      onClick={() => act('shutdown', { target_index: targetIndex })}
                    >
                      /proc/shutdown(target) - &lt;=10%
                    </Button>
                  )}
                  {canShowAction('emp_activate') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(true, !permissions.emp_activate)}
                    disabled={!permissions.emp_activate}
                    onClick={() =>
                      act('emp_activate', { target_index: targetIndex })
                    }
                  >
                    /proc/emp_activate(target) - &lt;=40%
                  </Button>
                  )}
                  {canShowAction('emag_activate') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(true, !permissions.emag_activate)}
                    disabled={!permissions.emag_activate}
                    onClick={() =>
                      act('emag_activate', { target_index: targetIndex })
                    }
                  >
                    /proc/emag_activate(target) - &lt;=70%
                  </Button>
                  )}
                  {canShowAction('settings') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      false,
                      !selectedObject.has_ui || !permissions.settings,
                    )}
                    disabled={!selectedObject.has_ui || !permissions.settings}
                    onClick={() => act('settings', { target_index: targetIndex })}
                  >
                    /proc/settings(target) - key / 0%
                  </Button>
                  )}
                  {canShowAction('door_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(false, !permissions.door_toggle)}
                    disabled={!permissions.door_toggle}
                    onClick={() =>
                      act('door_toggle', { target_index: targetIndex })
                    }
                  >
                    door motor toggle - key / 0%
                  </Button>
                  )}
                  {canShowAction('bolt_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(true, !permissions.bolt_toggle)}
                    disabled={!permissions.bolt_toggle}
                    onClick={() =>
                      act('bolt_toggle', { target_index: targetIndex })
                    }
                  >
                    bolt channel toggle - key / &lt;=40%
                  </Button>
                  )}
                  {canShowAction('electrify_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      true,
                      !permissions.electrify_toggle,
                    )}
                    disabled={!permissions.electrify_toggle}
                    onClick={() =>
                      act('electrify_toggle', { target_index: targetIndex })
                    }
                  >
                    electrification toggle - key / &lt;=40%
                  </Button>
                  )}
                  {canShowAction('camera_inspect') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(false, !permissions.camera_inspect)}
                    disabled={!permissions.camera_inspect}
                    onClick={() =>
                      act('camera_inspect', { target_index: targetIndex })
                    }
                  >
                    camera diagnostics - key / 0%
                  </Button>
                  )}
                  {canShowAction('camera_rotate') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(false, !permissions.camera_rotate)}
                    disabled={!permissions.camera_rotate}
                    onClick={() =>
                      act('camera_rotate', { target_index: targetIndex })
                    }
                  >
                    rotate camera - key / 0%
                  </Button>
                  )}
                  {canShowAction('panel_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(false, !permissions.panel_toggle)}
                    disabled={!permissions.panel_toggle}
                    onClick={() =>
                      act('panel_toggle', { target_index: targetIndex })
                    }
                  >
                    service panel toggle - key / 0%
                  </Button>
                  )}
                  {canShowAction('power_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(true, !permissions.power_toggle)}
                    disabled={!permissions.power_toggle}
                    onClick={() =>
                      act('power_toggle', { target_index: targetIndex })
                    }
                  >
                    local power toggle - key / 0%
                  </Button>
                  )}
                  {canShowAction('contraband_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      false,
                      !permissions.contraband_toggle,
                    )}
                    disabled={!permissions.contraband_toggle}
                    onClick={() =>
                      act('contraband_toggle', { target_index: targetIndex })
                    }
                  >
                    vending contraband toggle - key / 0%
                  </Button>
                  )}
                  {canShowAction('apc_breaker_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      true,
                      !permissions.apc_breaker_toggle,
                    )}
                    disabled={!permissions.apc_breaker_toggle}
                    onClick={() =>
                      act('apc_breaker_toggle', { target_index: targetIndex })
                    }
                  >
                    APC breaker toggle - key / 0%
                  </Button>
                  )}
                  {canShowAction('apc_nightshift_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      false,
                      !permissions.apc_nightshift_toggle,
                    )}
                    disabled={!permissions.apc_nightshift_toggle}
                    onClick={() =>
                      act('apc_nightshift_toggle', {
                        target_index: targetIndex,
                      })
                    }
                  >
                    APC night lights toggle - key / 0%
                  </Button>
                  )}
                  {canShowAction('turret_power_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      true,
                      !permissions.turret_power_toggle,
                    )}
                    disabled={!permissions.turret_power_toggle}
                    onClick={() =>
                      act('turret_power_toggle', {
                        target_index: targetIndex,
                      })
                    }
                  >
                    linked turrets power - key / 0%
                  </Button>
                  )}
                  {canShowAction('turret_lethal_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      true,
                      !permissions.turret_lethal_toggle,
                    )}
                    disabled={!permissions.turret_lethal_toggle}
                    onClick={() =>
                      act('turret_lethal_toggle', {
                        target_index: targetIndex,
                      })
                    }
                  >
                    linked turrets lethal mode - key / 0%
                  </Button>
                  )}
                  {canShowAction('turret_silicon_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(
                      true,
                      !permissions.turret_silicon_toggle,
                    )}
                    disabled={!permissions.turret_silicon_toggle}
                    onClick={() =>
                      act('turret_silicon_toggle', {
                        target_index: targetIndex,
                      })
                    }
                  >
                    linked turrets silicon target - key / 0%
                  </Button>
                  )}
                  {canShowAction('light_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(false, !permissions.light_toggle)}
                    disabled={!permissions.light_toggle}
                    onClick={() =>
                      act('light_toggle', { target_index: targetIndex })
                    }
                  >
                    light emitter toggle - key / 0%
                  </Button>
                  )}
                  {canShowAction('device_toggle') && (
                    <Button
                    fluid
                    color="transparent"
                    style={cyberButtonStyle(false, !permissions.device_toggle)}
                    disabled={!permissions.device_toggle}
                    onClick={() =>
                      act('device_toggle', { target_index: targetIndex })
                    }
                  >
                    device toggle - key / 0%
                  </Button>
                  )}
                  {selectedObject.functions?.length === 0 && (
                    <div style={{ color: cy.muted }}>No exposed control functions.</div>
                  )}
                </>
              ) : (
                <div style={{ color: cy.muted }}>Select a linked object.</div>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const NodeMetric = (props: {
  label: string;
  value: string | number;
  color?: string;
}) => (
  <div
    style={{
      border: `1px solid ${cy.cyanSoft}`,
      background: 'rgba(5, 8, 13, 0.72)',
      padding: '7px',
    }}
  >
    <div
      style={{ color: cy.muted, fontSize: '10px', textTransform: 'uppercase' }}
    >
      {props.label}
    </div>
    <div style={{ color: props.color || cy.cyan, fontWeight: 800 }}>
      {props.value}
    </div>
  </div>
);

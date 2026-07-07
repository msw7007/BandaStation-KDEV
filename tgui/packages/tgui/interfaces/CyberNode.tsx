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
  access: boolean;
  extracted: boolean;
  reserve: number;
  max_reserve: number;
  protection_integrity: number;
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
  const hasFunction = (functionId: string) =>
    !!selectedObject?.functions?.includes(functionId);
  const canShowAction = (functionId: string) => hasTarget && hasFunction(functionId);
  const objectAccess = !!selectedObject?.access || !!data.has_access;
  const objectIntegrity = selectedObject?.protection_integrity ?? 100;
  const actionDefinitions = [
    {
      functionId: 'interface',
      action: 'open_ui',
      label: 'open_ui - key / 0%',
      disabled: !selectedObject?.has_ui || !objectAccess,
    },
    {
      functionId: 'shutdown',
      action: 'shutdown',
      label: 'shutdown - <=10%',
      danger: true,
      disabled: objectIntegrity > 10,
    },
    {
      functionId: 'emp_activate',
      action: 'emp_activate',
      label: 'EMP - <=40%',
      danger: true,
      disabled: objectIntegrity > 40,
    },
    {
      functionId: 'emag_activate',
      action: 'emag_activate',
      label: 'EMAG - <=70%',
      danger: true,
      disabled: objectIntegrity > 70,
    },
    {
      functionId: 'settings',
      action: 'settings',
      label: 'settings - key / 0%',
      disabled: !selectedObject?.has_ui || !objectAccess,
    },
    {
      functionId: 'door_toggle',
      action: 'door_toggle',
      label: 'door motor - key / 0%',
      disabled: !objectAccess,
    },
    {
      functionId: 'bolt_toggle',
      action: 'bolt_toggle',
      label: 'bolts - key / <=40%',
      danger: true,
      disabled: !objectAccess && objectIntegrity > 40,
    },
    {
      functionId: 'electrify_toggle',
      action: 'electrify_toggle',
      label: 'electrify - key / <=40%',
      danger: true,
      disabled: !objectAccess && objectIntegrity > 40,
    },
    {
      functionId: 'camera_inspect',
      action: 'camera_inspect',
      label: 'camera diagnostics',
      disabled: !objectAccess,
    },
    {
      functionId: 'camera_rotate',
      action: 'camera_rotate',
      label: 'rotate camera',
      disabled: !objectAccess,
    },
    {
      functionId: 'panel_toggle',
      action: 'panel_toggle',
      label: 'service panel',
      disabled: !objectAccess,
    },
    {
      functionId: 'power_toggle',
      action: 'power_toggle',
      label: 'local power',
      danger: true,
      disabled: !objectAccess,
    },
    {
      functionId: 'contraband_toggle',
      action: 'contraband_toggle',
      label: 'contraband',
      disabled: !objectAccess,
    },
    {
      functionId: 'apc_breaker_toggle',
      action: 'apc_breaker_toggle',
      label: 'APC breaker',
      danger: true,
      disabled: !objectAccess,
    },
    {
      functionId: 'apc_nightshift_toggle',
      action: 'apc_nightshift_toggle',
      label: 'night lights',
      disabled: !objectAccess,
    },
    {
      functionId: 'turret_power_toggle',
      action: 'turret_power_toggle',
      label: 'turret power',
      danger: true,
      disabled: !objectAccess,
    },
    {
      functionId: 'turret_lethal_toggle',
      action: 'turret_lethal_toggle',
      label: 'turret lethal',
      danger: true,
      disabled: !objectAccess,
    },
    {
      functionId: 'turret_silicon_toggle',
      action: 'turret_silicon_toggle',
      label: 'turret silicon',
      danger: true,
      disabled: !objectAccess,
    },
    {
      functionId: 'light_toggle',
      action: 'light_toggle',
      label: 'light toggle',
      disabled: !objectAccess,
    },
    {
      functionId: 'device_toggle',
      action: 'device_toggle',
      label: 'device toggle',
      disabled: !objectAccess,
    },
  ];

  return (
    <Window title="Cyberspace node" width={860} height={600}>
      <Window.Content
        style={{
          background: cy.bg,
          color: cy.text,
          height: '100%',
          overflow: 'hidden',
        }}
      >
        <Stack fill>
          <Stack.Item width="45%">
            <Section
              fill
              scrollable
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

          <Stack.Item grow style={{ minHeight: 0 }}>
            <Stack vertical fill>
              <Stack.Item>
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
                      color={
                        (data.protection_integrity || 0) <= 10 ? cy.red : cy.cyan
                      }
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
                    style={cyberButtonStyle(true, false)}
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
              </Stack.Item>

              <Stack.Item grow style={{ minHeight: 0 }}>
                <Section
                  fill
                  scrollable
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
                          marginBottom: '6px',
                          padding: '6px 8px',
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
                            fontSize: '10px',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          {selectedObject.type}
                        </div>
                        <div
                          style={{
                            display: 'grid',
                            gridTemplateColumns: '1fr 1fr 1fr',
                            gap: '4px',
                            marginTop: '6px',
                          }}
                        >
                          <NodeMetric
                            label="Object ICE"
                            value={`${selectedObject.reserve}/${selectedObject.max_reserve}`}
                          />
                          <NodeMetric
                            label="Object integrity"
                            value={`${selectedObject.protection_integrity}%`}
                            color={
                              selectedObject.protection_integrity <= 10
                                ? cy.red
                                : cy.cyan
                            }
                          />
                          <NodeMetric
                            label="Object data"
                            value={
                              selectedObject.extracted ? 'extracted' : 'cached'
                            }
                            color={selectedObject.extracted ? cy.muted : cy.green}
                          />
                        </div>
                        <div
                          style={{
                            marginTop: '4px',
                            fontSize: '11px',
                            lineHeight: 1.25,
                          }}
                        >
                          <span style={{ color: cy.muted }}>Functions: </span>
                          <span style={{ color: cy.text }}>
                            {selectedObject.functions?.join(', ') ||
                              'inspect only'}
                          </span>
                        </div>
                        {selectedObject.critical_ice && (
                          <div style={{ color: cy.red, marginTop: '5px' }}>
                            Critical ICE endpoint. Use ICE breach for full
                            intrusion.
                          </div>
                        )}
                      </div>
                      <div
                        style={{
                          display: 'grid',
                          gridTemplateColumns: '1fr 1fr',
                          gap: '5px',
                        }}
                      >
                        {actionDefinitions
                          .filter((actionDefinition) =>
                            canShowAction(actionDefinition.functionId),
                          )
                          .map((actionDefinition) => (
                            <Button
                              key={actionDefinition.functionId}
                              fluid
                              color="transparent"
                              style={{
                                ...cyberButtonStyle(
                                  !!actionDefinition.danger,
                                  !!actionDefinition.disabled,
                                ),
                                marginBottom: 0,
                                padding: '5px 7px',
                                minHeight: '28px',
                                fontSize: '11px',
                                lineHeight: 1.15,
                              }}
                              disabled={!!actionDefinition.disabled}
                              onClick={() =>
                                act(actionDefinition.action, {
                                  target_index: targetIndex,
                                })
                              }
                            >
                              {actionDefinition.label}
                            </Button>
                          ))}
                      </div>
                      {selectedObject.functions?.length === 0 && (
                        <div style={{ color: cy.muted }}>
                          No exposed control functions.
                        </div>
                      )}
                    </>
                  ) : (
                    <div style={{ color: cy.muted }}>Select a linked object.</div>
                  )}
                </Section>
              </Stack.Item>
            </Stack>
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

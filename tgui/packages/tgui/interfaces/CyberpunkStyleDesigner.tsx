// CYBERPUNK BUILD - rebuild and delete before release
import { useEffect, useRef, useState } from 'react';
import {
  Box,
  Button,
  Input,
  LabeledList,
  Section,
  Stack,
  Tabs,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const CANVAS_SIZE = 32;
const CANVAS_PIXELS = CANVAS_SIZE * CANVAS_SIZE;

type VisualDesign = {
  id: string;
  name: string;
  kind: string;
  base?: string;
  type_path?: string;
  material_signature?: string;
  directions?: Record<string, string>;
  item_icon?: string;
};

type ClothingItem = {
  ref: string;
  name: string;
  typePath: string;
  active: boolean;
  modular: boolean;
  greyscaleColors?: string;
  iconState?: string;
  wornIconState?: string;
  itemPreview?: string;
  wornPreviews?: Record<string, string>;
  itemPayload?: string;
  wornPayloads?: Record<string, string>;
};

type DesignerData = {
  mode: 'hair' | 'clothing' | 'wardrobe';
  lastMessage?: string;
  hairDesigns: VisualDesign[];
  wardrobeDesigns: VisualDesign[];
  clothingItems: ClothingItem[];
  currentHair: string;
  currentHairColor: string;
  currentHairPreviews?: Record<string, string>;
  currentHairPayloads?: Record<string, string>;
  editableHairBase?: string;
  wardrobeLimit?: number;
  wardrobeCount?: number;
};

const hairLayers = {
  south: 'South',
  north: 'North',
  east: 'East',
  west: 'West',
};

const clothingLayers = {
  ...hairLayers,
  item: 'Item icon',
};

const blankGrid = () => Array(CANVAS_PIXELS).fill('');

const serializeGrid = (grid: string[]) =>
  grid
    .map((color, index) => (color ? `${index}:${color}` : ''))
    .filter(Boolean)
    .join(';');

const deserializeGrid = (payload = '') => {
  const grid = blankGrid();
  for (const part of payload.split(';')) {
    const [rawIndex, color] = part.split(':');
    const index = Number(rawIndex);
    if (Number.isFinite(index) && index >= 0 && index < CANVAS_PIXELS && color) {
      grid[index] = color;
    }
  }
  return grid;
};

const PixelCanvas = (props: {
  payload: string;
  baseImage?: string;
  color: string;
  erasing: boolean;
  onChange: (payload: string) => void;
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const drawingRef = useRef(false);
  const [grid, setGrid] = useState<string[]>(() =>
    deserializeGrid(props.payload),
  );

  useEffect(() => {
    setGrid(deserializeGrid(props.payload));
  }, [props.payload]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) {
      return;
    }
    const context = canvas.getContext('2d');
    if (!context) {
      return;
    }
    let cancelled = false;
    const scale = canvas.width / CANVAS_SIZE;
    const draw = (base?: HTMLImageElement) => {
      if (cancelled) {
        return;
      }
      context.clearRect(0, 0, canvas.width, canvas.height);
      context.fillStyle = '#101820';
      context.fillRect(0, 0, canvas.width, canvas.height);
      context.imageSmoothingEnabled = false;
      if (base) {
        context.drawImage(base, 0, 0, canvas.width, canvas.height);
      }
      for (let index = 0; index < grid.length; index++) {
        const color = grid[index];
        if (!color) {
          continue;
        }
        context.fillStyle = color;
        context.fillRect(
          (index % CANVAS_SIZE) * scale,
          Math.floor(index / CANVAS_SIZE) * scale,
          scale,
          scale,
        );
      }
      context.strokeStyle = 'rgba(5, 217, 232, 0.22)';
      context.lineWidth = 1;
      for (let line = 0; line <= CANVAS_SIZE; line++) {
        context.beginPath();
        context.moveTo(line * scale, 0);
        context.lineTo(line * scale, canvas.height);
        context.stroke();
        context.beginPath();
        context.moveTo(0, line * scale);
        context.lineTo(canvas.width, line * scale);
        context.stroke();
      }
    };
    if (props.baseImage) {
      const base = new Image();
      base.onload = () => draw(base);
      base.onerror = () => draw();
      base.src = `data:image/jpeg;base64,${props.baseImage}`;
    } else {
      draw();
    }
    return () => {
      cancelled = true;
    };
  }, [grid, props.baseImage]);

  const paint = (event) => {
    const canvas = canvasRef.current;
    if (!canvas) {
      return;
    }
    const rect = canvas.getBoundingClientRect();
    const x = Math.floor(((event.clientX - rect.left) / rect.width) * CANVAS_SIZE);
    const y = Math.floor(((event.clientY - rect.top) / rect.height) * CANVAS_SIZE);
    if (x < 0 || y < 0 || x >= CANVAS_SIZE || y >= CANVAS_SIZE) {
      return;
    }
    const index = y * CANVAS_SIZE + x;
    const next = [...grid];
    next[index] = props.erasing ? '' : props.color;
    setGrid(next);
    props.onChange(serializeGrid(next));
  };

  return (
    <canvas
      ref={canvasRef}
      width={320}
      height={320}
      style={{
        width: '320px',
        height: '320px',
        border: '1px solid #05d9e8',
        imageRendering: 'pixelated',
        cursor: 'crosshair',
      }}
      onMouseDown={(event) => {
        drawingRef.current = true;
        paint(event);
      }}
      onMouseMove={(event) => drawingRef.current && paint(event)}
      onMouseUp={() => (drawingRef.current = false)}
      onMouseLeave={() => (drawingRef.current = false)}
    />
  );
};

export const CyberpunkStyleDesigner = () => {
  const { act, data } = useBackend<DesignerData>();
  const [name, setName] = useState('');
  const [base, setBase] = useState(data.currentHair || '');
  const [color, setColor] = useState(data.currentHairColor || '#05d9e8');
  const [erasing, setErasing] = useState(false);
  const [activeLayer, setActiveLayer] = useState('south');
  const [iconState, setIconState] = useState('');
  const [wornIconState, setWornIconState] = useState('');
  const [importPayload, setImportPayload] = useState('');
  const [selectedClothingRef, setSelectedClothingRef] = useState('');
  const [directions, setDirections] = useState<Record<string, string>>({
    north: '',
    south: '',
    east: '',
    west: '',
    item: '',
  });

  const activeClothing =
    data.clothingItems?.find((item) => item.ref === selectedClothingRef) ||
    data.clothingItems?.find((item) => item.active) ||
    data.clothingItems?.[0];
  const availableLayers = data.mode === 'hair' ? hairLayers : clothingLayers;
  const records =
    data.mode === 'hair' ? data.hairDesigns || [] : data.wardrobeDesigns || [];
  const basePreview =
    data.mode === 'hair'
      ? directions[activeLayer]
        ? undefined
        : data.currentHairPreviews?.[activeLayer]
      : directions[activeLayer]
        ? undefined
        : activeLayer === 'item'
          ? activeClothing?.itemPreview
          : activeClothing?.wornPreviews?.[activeLayer];

  useEffect(() => {
    if (data.mode !== 'hair') {
      return;
    }
    const hasAnyEditableHairPayload = Object.values(
      data.currentHairPayloads || {},
    ).some(Boolean);
    const hasAnyLocalHairPayload = ['north', 'south', 'east', 'west'].some(
      (layer) => !!directions[layer],
    );
    if (hasAnyEditableHairPayload && !hasAnyLocalHairPayload) {
      setDirections({
        north: data.currentHairPayloads?.north || '',
        south: data.currentHairPayloads?.south || '',
        east: data.currentHairPayloads?.east || '',
        west: data.currentHairPayloads?.west || '',
        item: directions.item || '',
      });
      setBase(data.editableHairBase || 'Bald');
    } else if (!base && data.currentHair) {
      setBase(data.editableHairBase || data.currentHair);
    }
    if (!name && data.currentHair) {
      setName(`Custom ${data.currentHair}`);
    }
    if ((!color || color === '#05d9e8') && data.currentHairColor) {
      setColor(data.currentHairColor);
    }
  }, [data.mode, data.currentHair, data.currentHairColor]);

  useEffect(() => {
    if (data.mode !== 'clothing' || !activeClothing) {
      return;
    }
    if (!selectedClothingRef) {
      setSelectedClothingRef(activeClothing.ref);
    }
    setName(activeClothing.name || '');
    setColor(activeClothing.greyscaleColors || '#ffffff');
    setIconState(activeClothing.iconState || '');
    setWornIconState(activeClothing.wornIconState || '');
    setDirections({
      north: activeClothing.wornPayloads?.north || '',
      south: activeClothing.wornPayloads?.south || '',
      east: activeClothing.wornPayloads?.east || '',
      west: activeClothing.wornPayloads?.west || '',
      item: activeClothing.itemPayload || '',
    });
  }, [data.mode, activeClothing?.ref]);

  useEffect(() => {
    if (!(activeLayer in availableLayers)) {
      setActiveLayer('south');
    }
  }, [data.mode, activeLayer]);

  const setLayerPayload = (layer: string, payload: string) => {
    setDirections({
      ...directions,
      [layer]: payload,
    });
  };

  const loadRecord = (record: VisualDesign) => {
    setName(record.name || '');
    setBase(record.base || data.currentHair || '');
    setDirections({
      north: record.directions?.north || '',
      south: record.directions?.south || '',
      east: record.directions?.east || '',
      west: record.directions?.west || '',
      item: record.item_icon || '',
    });
  };

  const payload = () => ({
    id: data.mode === 'hair' ? 'active_custom_hair' : undefined,
    name: name || (data.mode === 'hair' ? 'custom hair' : activeClothing?.name),
    targetRef: activeClothing?.ref,
    base,
    greyscaleColors: color || activeClothing?.greyscaleColors || '',
    iconState: iconState || activeClothing?.iconState || '',
    wornIconState: wornIconState || activeClothing?.wornIconState || '',
    itemIcon: directions.item,
    north: directions.north,
    south: directions.south,
    east: directions.east,
    west: directions.west,
  });

  return (
    <Window
      title={
        data.mode === 'hair'
          ? 'Stylist module'
          : data.mode === 'wardrobe'
            ? 'Wardrobe'
            : 'Design module'
      }
      width={900}
      height={760}
    >
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="Workspace">
          <Stack>
            <Stack.Item grow className="CyberpunkPanel__Metric">
              <Box className="CyberpunkPanel__Title">
                {data.mode === 'hair'
                  ? 'Custom hair'
                  : data.mode === 'wardrobe'
                    ? 'Persistent wardrobe'
                    : 'Custom clothing'}
              </Box>
              <Box className="CyberpunkPanel__Muted">
                Draw 32x32 cache layers. Runtime DMI baking is the next backend
                step.
              </Box>
            </Stack.Item>
            {data.mode === 'hair' && (
              <Stack.Item className="CyberpunkPanel__Metric">
                <Box className="CyberpunkPanel__Muted">Current hair</Box>
                <Box className="CyberpunkPanel__Title">
                  {data.currentHair || 'none'}
                </Box>
                {!!data.currentHairColor && (
                  <Stack align="center" mt={0.5}>
                    <Stack.Item>
                      <Box
                        style={{
                          width: '18px',
                          height: '18px',
                          background: data.currentHairColor,
                          border: '1px solid #88f7ff',
                        }}
                      />
                    </Stack.Item>
                    <Stack.Item className="CyberpunkPanel__Small">
                      {data.currentHairColor}
                    </Stack.Item>
                  </Stack>
                )}
              </Stack.Item>
            )}
          </Stack>
          {!!data.lastMessage && (
            <Box mt={1} className="CyberpunkPanel__Card">
              {data.lastMessage}
            </Box>
          )}
        </Section>

        {data.mode === 'clothing' && (
          <Section title="Clothing target">
            {data.clothingItems?.length ? (
              <Stack wrap>
                {data.clothingItems.map((item) => (
                  <Stack.Item key={item.ref}>
                    <Button
                      selected={activeClothing?.ref === item.ref}
                      color={item.modular ? undefined : 'bad'}
                      tooltip={
                        item.modular
                          ? item.typePath
                          : 'Not modular: can preview/edit states, wardrobe storage will reject it.'
                      }
                      onClick={() => {
                        setSelectedClothingRef(item.ref);
                        setName(item.name || '');
                        setColor(item.greyscaleColors || '#ffffff');
                        setIconState(item.iconState || '');
                        setWornIconState(item.wornIconState || '');
                      }}
                    >
                      {item.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            ) : (
              <Box className="CyberpunkPanel__Muted">
                No clothing in hands or pockets.
              </Box>
            )}
          </Section>
        )}

        {data.mode !== 'wardrobe' && (
          <Section title="Pixel editor">
            <Stack align="start">
              <Stack.Item>
                <Tabs vertical>
                  {Object.entries(availableLayers).map(([id, label]) => (
                    <Tabs.Tab
                      key={id}
                      selected={activeLayer === id}
                      onClick={() => setActiveLayer(id)}
                    >
                      {label}
                    </Tabs.Tab>
                  ))}
                </Tabs>
              </Stack.Item>
              <Stack.Item>
                <PixelCanvas
                  payload={directions[activeLayer] || ''}
                  baseImage={basePreview}
                  color={color}
                  erasing={erasing}
                  onChange={(value) => setLayerPayload(activeLayer, value)}
                />
              </Stack.Item>
              <Stack.Item grow>
                <LabeledList>
                  <LabeledList.Item label="Name">
                    <Input fluid value={name} onChange={setName} />
                  </LabeledList.Item>
                  {data.mode === 'hair' && (
                    <LabeledList.Item label="Base hair">
                      <Input fluid value={base} onChange={setBase} />
                    </LabeledList.Item>
                  )}
                  <LabeledList.Item label="Color">
                    <Stack align="center">
                      <Stack.Item>
                        <input
                          type="color"
                          value={color || '#05d9e8'}
                          onChange={(event) => setColor(event.target.value)}
                        />
                      </Stack.Item>
                      <Stack.Item className="CyberpunkPanel__Small">
                        {color || '#05d9e8'}
                      </Stack.Item>
                    </Stack>
                  </LabeledList.Item>
                  {data.mode === 'clothing' && (
                    <>
                      <LabeledList.Item label="Icon state">
                        <Input
                          fluid
                          value={iconState}
                          placeholder={activeClothing?.iconState}
                          onChange={setIconState}
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Worn state">
                        <Input
                          fluid
                          value={wornIconState}
                          placeholder={activeClothing?.wornIconState}
                          onChange={setWornIconState}
                        />
                      </LabeledList.Item>
                    </>
                  )}
                </LabeledList>

                <Stack mt={1}>
                  <Stack.Item>
                    <Button
                      icon="eraser"
                      selected={erasing}
                      onClick={() => setErasing(!erasing)}
                    >
                      Eraser
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="trash"
                      onClick={() => setLayerPayload(activeLayer, '')}
                    >
                      Clear layer
                    </Button>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="floppy-disk"
                      onClick={() =>
                        act(
                          data.mode === 'hair' ? 'save_hair' : 'save_clothing',
                          payload(),
                        )
                      }
                    >
                      Save and apply
                    </Button>
                  </Stack.Item>
                </Stack>

                <Section title="Cache import / export" mt={1}>
                  <TextArea
                    fluid
                    height="70px"
                    value={importPayload || directions[activeLayer] || ''}
                    onChange={setImportPayload}
                  />
                  <Stack mt={0.5}>
                    <Stack.Item grow>
                      <Button
                        fluid
                        icon="upload"
                        onClick={() =>
                          setLayerPayload(activeLayer, importPayload)
                        }
                      >
                        Load into active layer
                      </Button>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Button
                        fluid
                        icon="download"
                        onClick={() =>
                          setImportPayload(directions[activeLayer] || '')
                        }
                      >
                        Copy active layer
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
          </Section>
        )}

        {data.mode === 'wardrobe' && (
          <Section title="Wardrobe intake">
            <Stack align="center" mb={1}>
              <Stack.Item grow>
                <Box className="CyberpunkPanel__Metric">
                  <Box className="CyberpunkPanel__Muted">Capacity</Box>
                  <Box className="CyberpunkPanel__Title">
                    {data.wardrobeCount || 0} / {data.wardrobeLimit || 1}
                  </Box>
                </Box>
              </Stack.Item>
            </Stack>
            <Button
              fluid
              icon="box-archive"
              disabled={(data.wardrobeCount || 0) >= (data.wardrobeLimit || 1)}
              onClick={() => act('store_wardrobe')}
            >
              Store active modular clothing
            </Button>
            <Box mt={1} className="CyberpunkPanel__Muted">
              Stored clothing is consumed. Hardware modules and inserts are not
              preserved. Capacity is tied to your account: 1 + donator tier.
            </Box>
          </Section>
        )}

        <Section
          title={
            data.mode === 'hair'
              ? 'Hair cache'
              : data.mode === 'clothing'
                ? 'Saved wardrobe designs'
                : 'Wardrobe cache'
          }
        >
          {records.length ? (
            records.map((record) => (
              <Box key={record.id} className="CyberpunkPanel__Card">
                <Stack align="center">
                  <Stack.Item grow>
                    <Box className="CyberpunkPanel__Title">{record.name}</Box>
                    <Box className="CyberpunkPanel__Muted">
                      {record.kind} {record.base ? `/ ${record.base}` : ''}
                    </Box>
                    {!!record.type_path && (
                      <Box className="CyberpunkPanel__Small">
                        {record.type_path}
                      </Box>
                    )}
                    {!!record.material_signature && (
                      <Box className="CyberpunkPanel__Small">
                        Materials: {record.material_signature}
                      </Box>
                    )}
                  </Stack.Item>
                  <Stack.Item>
                    {data.mode !== 'wardrobe' && (
                      <Button
                        icon="folder-open"
                        mr={0.5}
                        onClick={() => loadRecord(record)}
                      >
                        Load
                      </Button>
                    )}
                    {data.mode === 'wardrobe' ? (
                      <>
                        <Button
                          icon="shirt"
                          mr={0.5}
                          onClick={() =>
                            act('extract_wardrobe', { id: record.id })
                          }
                        >
                          Extract
                        </Button>
                        <Button
                          icon="trash"
                          color="bad"
                          onClick={() =>
                            act('remove_wardrobe', { id: record.id })
                          }
                        >
                          Remove
                        </Button>
                      </>
                    ) : data.mode === 'clothing' ? (
                      <Button
                        icon="paintbrush"
                        onClick={() => act('apply_clothing', { id: record.id })}
                      >
                        Apply
                      </Button>
                    ) : null}
                  </Stack.Item>
                </Stack>
              </Box>
            ))
          ) : (
            <Box className="CyberpunkPanel__Muted">No saved records.</Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release

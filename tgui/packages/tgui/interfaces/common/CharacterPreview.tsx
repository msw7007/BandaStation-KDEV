import { ByondUi } from 'tgui-core/components';

export const CharacterPreview = (props: {
  height: string;
  id: string;
  imageBase64?: string;
  scale?: number;
  scaleX?: number;
  scaleY?: number;
  transparent?: boolean;
  width?: string;
}) => {
  if (props.imageBase64) {
    const baseScale = props.scale ?? 1;
    const imageScaleX = baseScale * (props.scaleX ?? 1);
    const imageScaleY = baseScale * (props.scaleY ?? 1);

    return (
      <div
        className="CharacterPreview CharacterPreview--image"
        style={{
          height: props.height,
          width: props.width ?? '220px',
        }}
      >
        <img
          src={`data:image/png;base64,${props.imageBase64}`}
          style={{
            transform: `scale(${imageScaleX}, ${imageScaleY})`,
            transformOrigin: 'center bottom',
          }}
        />
      </div>
    );
  }

  return (
    <div className="CharacterPreview">
      <ByondUi
        height={props.height}
        width={props.width ?? '220px'}
        params={{
          id: props.id,
          type: 'map',
          ...(props.transparent
            ? {
                background: 'transparent',
                backgroundColor: 'transparent',
                background_color: 'transparent',
                transparent: true,
              }
            : {}),
        }}
      />
    </div>
  );
};

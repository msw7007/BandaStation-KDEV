import type { PropsWithChildren, ReactNode } from 'react';
import { classes } from 'tgui-core/react';

type CyberPanelProps = PropsWithChildren<{
  title?: ReactNode;
  subtitle?: ReactNode;
  buttons?: ReactNode;
  className?: string;
  scrollable?: boolean;
}>;

export function CyberPanel(props: CyberPanelProps) {
  const { buttons, children, className, scrollable, subtitle, title } = props;

  return (
    <section
      className={classes(['CyberPanel', scrollable && 'scrollable', className])}
    >
      {!!title && (
        <header className="CyberPanel__header">
          <div>
            <div className="CyberPanel__title">{title}</div>
            {!!subtitle && <div className="CyberPanel__subtitle">{subtitle}</div>}
          </div>
          {!!buttons && <div className="CyberPanel__buttons">{buttons}</div>}
        </header>
      )}
      <div className="CyberPanel__content">{children}</div>
    </section>
  );
}

export function CyberSectionHeader(props: PropsWithChildren) {
  return <div className="CyberSectionHeader">{props.children}</div>;
}


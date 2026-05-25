import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

export type CyberTab = {
  id: string;
  label: string;
  icon?: string;
};

type CyberTabsProps = {
  tabs: CyberTab[];
  activeTab: string;
  onSelect: (tab: string) => void;
};

export function CyberTabs(props: CyberTabsProps) {
  const { activeTab, onSelect, tabs } = props;

  return (
    <nav className="CyberTabs">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          className={classes(['CyberTabs__tab', activeTab === tab.id && 'active'])}
          onClick={() => onSelect(tab.id)}
        >
          {!!tab.icon && <Icon name={tab.icon} />}
          <span>{tab.label}</span>
        </button>
      ))}
    </nav>
  );
}


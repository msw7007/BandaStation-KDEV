export const pillColor = (color: string) =>
  ({
    red: '#d95757',
    blue: '#4f8bd9',
    yellow: '#d9bc4f',
    green: '#61a66a',
  })[color] || '#7b8794';

export const tileColor = (level: number) =>
  ['#2d3948', '#4f8bd9', '#d890d2', '#e6bd73', '#e46a72'][level] ||
  '#e46a72';

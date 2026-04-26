import fs from 'fs';
import path from 'path';

const walkSync = (dir, filelist = []) => {
  fs.readdirSync(dir).forEach(file => {
    const dirFile = path.join(dir, file);
    try { filelist = walkSync(dirFile, filelist); }
    catch (err) { if (err.code === 'ENOTDIR' || err.code === 'EBADF') filelist.push(dirFile); }
  });
  return filelist;
};

const files = walkSync('./app').filter(f => f.endsWith('.tsx') || f.endsWith('.ts'));

files.forEach(file => {
  let content = fs.readFileSync(file, 'utf-8');

  // Colors
  content = content.replace(/#0F1729/g, '#141414');
  content = content.replace(/#E24B4A/g, '#5A5A40');
  content = content.replace(/#EF9F27/g, '#8A8263');
  content = content.replace(/#1D9E75/g, '#475B49');
  content = content.replace(/#3B82F6/g, '#4A5868');
  content = content.replace(/#F5F6FA/g, '#F5F5F0');
  content = content.replace(/#FFFFFF/g, '#F5F5F0');
  content = content.replace(/bg-white/g, 'bg-[#F5F5F0]');
  content = content.replace(/text-white/g, 'text-[#F5F5F0]');
  content = content.replace(/border-white/g, 'border-[#F5F5F0]');
  content = content.replace(/fill-white/g, 'fill-[#F5F5F0]');
  
  // Muted colors and borders
  content = content.replace(/#EBEBEB/g, 'rgba(20,20,20,0.1)');
  content = content.replace(/#888888/g, 'rgba(20,20,20,0.6)');
  content = content.replace(/#BBBBBB/g, 'rgba(20,20,20,0.4)');
  
  // Success/Warning backgrounds
  content = content.replace(/#F0FDF7/g, '#EFEFE8');
  content = content.replace(/#6EE7B7/g, 'rgba(20,20,20,0.15)');
  content = content.replace(/#085041/g, '#141414');
  
  content = content.replace(/#FFF0F0/g, '#EFEFE8');
  content = content.replace(/#FECACA/g, 'rgba(20,20,20,0.1)');
  content = content.replace(/#FCE8E8/g, '#E8E8E0');
  
  content = content.replace(/#FFFBEB/g, '#EFEFE8');
  content = content.replace(/#FDE68A/g, 'rgba(20,20,20,0.1)');
  content = content.replace(/#FEF3C7/g, '#E8E8E0');
  
  content = content.replace(/#EFF6FF/g, '#EFEFE8');
  content = content.replace(/#BFDBFE/g, 'rgba(20,20,20,0.1)');
  content = content.replace(/#DBEAFE/g, '#E8E8E0');
  
  content = content.replace(/#FFF8F0/g, '#EFEFE8');
  content = content.replace(/#854F0B/g, '#141414');
  
  // AI card colors
  content = content.replace(/#F8F7FF/g, '#F5F5F0');
  content = content.replace(/#AFA9EC/g, 'rgba(20,20,20,0.2)');
  content = content.replace(/#534AB7/g, '#141414');
  content = content.replace(/#3C3489/g, '#141414');
  
  // Grey background replacements
  content = content.replace(/#FAFAFA/g, '#EFEFDF');
  content = content.replace(/#F8F9FB/g, '#F2F2EC');
  content = content.replace(/#F5F5F5/g, '#EBEBE4');

  // Typography -> Make headings serif and larger, remove semantics of weight
  content = content.replace(/text-\[32px\]/g, 'text-[42px] font-serif tracking-tight leading-none');
  content = content.replace(/text-\[26px\]/g, 'text-[36px] font-serif tracking-tight leading-none');
  content = content.replace(/text-\[24px\]/g, 'text-[32px] font-serif tracking-tight leading-none');
  content = content.replace(/text-\[20px\]/g, 'text-[28px] font-serif tracking-tight');
  content = content.replace(/text-\[16px\]/g, 'text-[18px] font-serif tracking-tight');
  content = content.replace(/text-\[15px\]/g, 'text-[16px] font-serif tracking-tight');
  
  content = content.replace(/font-semibold/g, 'font-medium');
  content = content.replace(/font-bold/g, 'font-medium');

  // UI shapes -> Remove rounded corners, except for full circles (like pills/avatars)
  // We'll replace rounded-xl, rounded-[14px], etc. with rounded-none
  content = content.replace(/rounded-xl/g, 'rounded-none');
  content = content.replace(/rounded-\[14px\]/g, 'rounded-none');
  content = content.replace(/rounded-\[24px\]/g, 'rounded-none');
  content = content.replace(/rounded-\[10px\]/g, 'rounded-none');
  content = content.replace(/rounded-lg/g, 'rounded-none');
  content = content.replace(/rounded-md/g, 'rounded-none');
  // keep rounded-full
  
  content = content.replace(/border-dashed/g, 'border-solid');
  content = content.replace(/shadow-lg/g, 'shadow-none');
  content = content.replace(/shadow-2xl/g, 'shadow-none border border-[rgba(20,20,20,0.1)]');
  
  // Replace arbitrary rounded properties cleanly
  content = content.replace(/rounded-\[.*?\]/g, (match) => {
    if (match === 'rounded-[100px]') return match;
    return 'rounded-none';
  });

  fs.writeFileSync(file, content, 'utf-8');
});

console.log("Theme updated");

function addQuoteLine(){const wrap=document.getElementById('quote-lines');if(!wrap)return;const n=wrap.querySelectorAll('.quote-line').length;const row=document.createElement('div');row.className='quote-line';row.innerHTML='<label>Description<input required name="lines['+n+'][description]"></label><label>Qty<input required min="0.01" step="0.01" type="number" name="lines['+n+'][quantity]" value="1"></label><label>Unit price MAD<input required min="0" step="0.01" type="number" name="lines['+n+'][unit_price]" value="0"></label>';wrap.appendChild(row);}

document.addEventListener('DOMContentLoaded', () => {
  const mode = document.getElementById('planning-mode');
  const custom = document.getElementById('custom-days');
  if (mode && custom) {
    const sync = () => { custom.hidden = mode.value !== 'custom'; };
    mode.addEventListener('change', sync);
    sync();
  }
});

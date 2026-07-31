const { execSync } = require('child_process');

let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input.trim());

    // Model name (shorten "Claude " prefix)
    const model = (data.model?.display_name || 'Claude').replace(/^Claude\s+/, '');

    // Git branch
    let branch = '';
    const cwd = data.cwd || data.workspace?.current_dir || '';
    if (cwd) {
      try {
        branch = execSync('git branch --show-current', {
          cwd,
          timeout: 1000,
          stdio: ['pipe', 'pipe', 'pipe']
        }).toString().trim();
      } catch {}
    }

    // Context progress bar
    const usedPct = data.context_window?.used_percentage;
    let ctxBar = '';
    if (usedPct != null) {
      const filled = Math.round(usedPct / 10);
      const empty = 10 - filled;
      ctxBar = '\u2588'.repeat(filled) + '\u2591'.repeat(empty) + ` ${Math.floor(usedPct)}%`;
    }

    // Code changes
    const added = data.cost?.total_lines_added;
    const removed = data.cost?.total_lines_removed;
    let changes = '';
    if (added != null || removed != null) {
      changes = `+${added || 0} -${removed || 0}`;
    }

    // Session duration
    const durationMs = data.cost?.total_duration_ms;
    let duration = '';
    if (durationMs != null && durationMs > 0) {
      const totalSec = Math.floor(durationMs / 1000);
      const h = Math.floor(totalSec / 3600);
      const m = Math.floor((totalSec % 3600) / 60);
      duration = h > 0 ? `${h}h${m}m` : `${m}m`;
    }

    // Cost
    const cost = data.cost?.total_cost_usd;
    const costStr = cost != null ? `$${cost.toFixed(2)}` : '';

    // Build status line
    const parts = [model];
    if (branch) parts.push(branch);
    if (ctxBar) parts.push(ctxBar);
    if (changes) parts.push(changes);
    if (duration) parts.push(duration);
    if (costStr) parts.push(costStr);

    process.stdout.write(parts.join(' | '));
  } catch {
    const m = input.match(/"display_name"\s*:\s*"([^"]*)"/);
    process.stdout.write(m ? m[1] : 'Claude');
  }
});

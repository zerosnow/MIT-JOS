#include <inc/assert.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/monitor.h>


// Choose a user environment to run and run it.
void
sched_yield(void)
{
	// Implement simple round-robin scheduling.
	// Search through 'envs' for a runnable environment,
	// in circular fashion starting after the previously running env,
	// and switch to the first such environment found.
	// It's OK to choose the previously running env if no other env
	// is runnable.
	// But never choose envs[0], the idle environment,
	// unless NOTHING else is runnable.

	// LAB 4: Your code here.
	int i, j, k;
	if (curenv == NULL)  {
		//cprintf("first environment run! \n");
		i=0;
	}
	else i = ENVX(curenv->env_id);
	for (j=(i+1)%NENV, k=0;k<NENV; j++,k++) {
		if (j %NENV == 0) ;
		else {
			if (envs[j %NENV].env_status == ENV_RUNNABLE) {
				//cprintf("env no : %d\n", j%NENV);
				env_run(&envs[j % NENV]);
				return;
			}
		}
	}
	// int i;
	// if (curenv == NULL) {
	// 	for (i=1;i<NENV;i++)
	// 		if (envs[i].env_status == ENV_RUNNABLE)
	// 			env_run(&envs[i]);
	// }else {
	// 	for (i=curenv->env_id;i<NENV;i++)
	// 		if (envs[i].env_status == ENV_RUNNABLE)
	// 			env_run(&envs[i]);
	// 	for (i=1;i<curenv->env_id;i++)
	// 		if (envs[i].env_status == ENV_RUNNABLE)
	// 			env_run(&envs[i]);
	// }
	


	// Run the special idle environment when nothing else is runnable.
	if (envs[0].env_status == ENV_RUNNABLE)
		env_run(&envs[0]);
	else {
		cprintf("Destroyed all environments - nothing more to do!\n");
		while (1)
			monitor(NULL);
	}
}

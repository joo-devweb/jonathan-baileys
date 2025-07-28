#!/usr/bin/env python3
"""
WhatsApp Defender - Performance Monitor (Python)
Backup monitoring system dengan Python untuk cross-platform compatibility
"""

import psutil
import time
import json
import os
import sys
import threading
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging
import signal

class PerformaMonitorPython:
    def __init__(self):
        self.stats = {
            'cpu': {
                'usage': 0.0,
                'cores': psutil.cpu_count(),
                'freq': psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None,
                'load_avg': os.getloadavg() if hasattr(os, 'getloadavg') else None
            },
            'memory': {
                'total': psutil.virtual_memory().total,
                'available': psutil.virtual_memory().available,
                'used': psutil.virtual_memory().used,
                'percent': psutil.virtual_memory().percent,
                'swap': psutil.swap_memory()._asdict()
            },
            'disk': {
                'usage': {},
                'io': psutil.disk_io_counters()._asdict() if psutil.disk_io_counters() else None
            },
            'network': {
                'io': psutil.net_io_counters()._asdict() if psutil.net_io_counters() else None,
                'connections': len(psutil.net_connections())
            },
            'process': {
                'pid': os.getpid(),
                'cpu_percent': 0.0,
                'memory_info': {},
                'num_threads': 0,
                'create_time': psutil.Process().create_time()
            }
        }
        
        self.monitoring = False
        self.threads = []
        self.log_file = './logs/performance_python.json'
        self.history = []
        self.max_history = 10000
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('./logs/performance_monitor.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)

    def signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.stop_monitoring()
        sys.exit(0)

    def start_monitoring(self):
        """Start all monitoring threads"""
        if self.monitoring:
            self.logger.warning("Monitoring already started")
            return
        
        self.monitoring = True
        self.logger.info("🚀 Starting Python Performance Monitor...")
        
        # Create monitoring threads
        threads_config = [
            ('CPU Monitor', self.monitor_cpu, 1),
            ('Memory Monitor', self.monitor_memory, 2),
            ('Disk Monitor', self.monitor_disk, 5),
            ('Network Monitor', self.monitor_network, 3),
            ('Process Monitor', self.monitor_process, 2),
            ('Stats Logger', self.log_stats, 10),
            ('Performance Optimizer', self.optimize_performance, 30)
        ]
        
        for name, target, interval in threads_config:
            thread = threading.Thread(
                target=self.run_monitor,
                args=(target, interval, name),
                daemon=True
            )
            thread.start()
            self.threads.append(thread)
            self.logger.info(f"✅ Started {name}")
        
        # Start stats display
        display_thread = threading.Thread(
            target=self.display_stats,
            daemon=True
        )
        display_thread.start()
        self.threads.append(display_thread)
        
        self.logger.info("✅ All monitoring threads started")

    def run_monitor(self, monitor_func, interval: float, name: str):
        """Run a monitoring function in a loop"""
        while self.monitoring:
            try:
                monitor_func()
                time.sleep(interval)
            except Exception as e:
                self.logger.error(f"Error in {name}: {e}")
                time.sleep(interval)

    def monitor_cpu(self):
        """Monitor CPU usage and performance"""
        try:
            # CPU usage percentage
            cpu_percent = psutil.cpu_percent(interval=None)
            self.stats['cpu']['usage'] = cpu_percent
            
            # CPU frequency
            if psutil.cpu_freq():
                self.stats['cpu']['freq'] = psutil.cpu_freq()._asdict()
            
            # Load average (Unix-like systems only)
            if hasattr(os, 'getloadavg'):
                self.stats['cpu']['load_avg'] = os.getloadavg()
            
            # Per-core usage
            per_cpu = psutil.cpu_percent(percpu=True)
            self.stats['cpu']['per_core'] = per_cpu
            
            # CPU times
            cpu_times = psutil.cpu_times_percent()
            self.stats['cpu']['times'] = cpu_times._asdict()
            
        except Exception as e:
            self.logger.error(f"CPU monitoring error: {e}")

    def monitor_memory(self):
        """Monitor memory usage"""
        try:
            # Virtual memory
            vmem = psutil.virtual_memory()
            self.stats['memory'].update({
                'total': vmem.total,
                'available': vmem.available,
                'used': vmem.used,
                'percent': vmem.percent,
                'free': vmem.free,
                'buffers': getattr(vmem, 'buffers', 0),
                'cached': getattr(vmem, 'cached', 0)
            })
            
            # Swap memory
            swap = psutil.swap_memory()
            self.stats['memory']['swap'] = swap._asdict()
            
        except Exception as e:
            self.logger.error(f"Memory monitoring error: {e}")

    def monitor_disk(self):
        """Monitor disk usage and I/O"""
        try:
            # Disk usage for all mounted disks
            disk_usage = {}
            for partition in psutil.disk_partitions():
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    disk_usage[partition.device] = {
                        'total': usage.total,
                        'used': usage.used,
                        'free': usage.free,
                        'percent': (usage.used / usage.total) * 100,
                        'mountpoint': partition.mountpoint,
                        'fstype': partition.fstype
                    }
                except PermissionError:
                    continue
            
            self.stats['disk']['usage'] = disk_usage
            
            # Disk I/O counters
            if psutil.disk_io_counters():
                self.stats['disk']['io'] = psutil.disk_io_counters()._asdict()
            
        except Exception as e:
            self.logger.error(f"Disk monitoring error: {e}")

    def monitor_network(self):
        """Monitor network usage and connections"""
        try:
            # Network I/O counters
            if psutil.net_io_counters():
                net_io = psutil.net_io_counters()
                self.stats['network']['io'] = net_io._asdict()
            
            # Network connections
            connections = psutil.net_connections()
            self.stats['network']['connections'] = len(connections)
            
            # Connection states
            conn_states = {}
            for conn in connections:
                state = conn.status
                conn_states[state] = conn_states.get(state, 0) + 1
            
            self.stats['network']['connection_states'] = conn_states
            
        except Exception as e:
            self.logger.error(f"Network monitoring error: {e}")

    def monitor_process(self):
        """Monitor current process performance"""
        try:
            process = psutil.Process()
            
            # CPU usage
            cpu_percent = process.cpu_percent()
            self.stats['process']['cpu_percent'] = cpu_percent
            
            # Memory info
            memory_info = process.memory_info()
            self.stats['process']['memory_info'] = memory_info._asdict()
            
            # Memory percent
            self.stats['process']['memory_percent'] = process.memory_percent()
            
            # Number of threads
            self.stats['process']['num_threads'] = process.num_threads()
            
            # File descriptors (Unix-like systems)
            try:
                self.stats['process']['num_fds'] = process.num_fds()
            except AttributeError:
                pass  # Windows doesn't have file descriptors
            
            # Process status
            self.stats['process']['status'] = process.status()
            
        except Exception as e:
            self.logger.error(f"Process monitoring error: {e}")

    def optimize_performance(self):
        """Perform automatic performance optimizations"""
        try:
            cpu_usage = self.stats['cpu']['usage']
            memory_percent = self.stats['memory']['percent']
            
            self.logger.info(f"🔧 Performance check - CPU: {cpu_usage:.1f}%, Memory: {memory_percent:.1f}%")
            
            # CPU optimization
            if cpu_usage > 90:
                self.optimize_cpu()
            
            # Memory optimization
            if memory_percent > 85:
                self.optimize_memory()
            
            # Disk cleanup
            self.cleanup_disk()
            
        except Exception as e:
            self.logger.error(f"Performance optimization error: {e}")

    def optimize_cpu(self):
        """Optimize CPU usage"""
        try:
            self.logger.info("🔥 High CPU usage detected, optimizing...")
            
            # Set process priority (requires appropriate permissions)
            process = psutil.Process()
            try:
                if sys.platform == 'win32':
                    process.nice(psutil.HIGH_PRIORITY_CLASS)
                else:
                    process.nice(-10)  # Higher priority on Unix-like systems
                self.logger.info("⚡ Process priority optimized")
            except psutil.AccessDenied:
                self.logger.warning("⚠️  Cannot change process priority (insufficient permissions)")
            
            # Force garbage collection in Python
            import gc
            gc.collect()
            self.logger.info("🗑️  Garbage collection performed")
            
        except Exception as e:
            self.logger.error(f"CPU optimization error: {e}")

    def optimize_memory(self):
        """Optimize memory usage"""
        try:
            self.logger.info("🧹 High memory usage detected, optimizing...")
            
            # Force garbage collection
            import gc
            gc.collect()
            
            # Trim history if too large
            if len(self.history) > self.max_history:
                self.history = self.history[-self.max_history//2:]
                self.logger.info("📊 History trimmed to optimize memory")
            
        except Exception as e:
            self.logger.error(f"Memory optimization error: {e}")

    def cleanup_disk(self):
        """Clean up disk space"""
        try:
            # Clean up old log files
            log_dir = './logs'
            if os.path.exists(log_dir):
                current_time = time.time()
                for filename in os.listdir(log_dir):
                    filepath = os.path.join(log_dir, filename)
                    if os.path.isfile(filepath):
                        # Delete files older than 7 days
                        if current_time - os.path.getmtime(filepath) > 7 * 24 * 3600:
                            os.remove(filepath)
                            self.logger.info(f"🗑️  Deleted old log file: {filename}")
            
        except Exception as e:
            self.logger.error(f"Disk cleanup error: {e}")

    def log_stats(self):
        """Log performance statistics"""
        try:
            log_entry = {
                'timestamp': datetime.now().isoformat(),
                'stats': self.stats.copy(),
                'monitor_type': 'python'
            }
            
            # Add to history
            self.history.append(log_entry)
            
            # Trim history if too large
            if len(self.history) > self.max_history:
                self.history = self.history[-self.max_history:]
            
            # Save to file
            self.save_to_file(log_entry)
            
        except Exception as e:
            self.logger.error(f"Stats logging error: {e}")

    def save_to_file(self, entry: Dict[str, Any]):
        """Save log entry to file"""
        try:
            # Ensure logs directory exists
            os.makedirs(os.path.dirname(self.log_file), exist_ok=True)
            
            # Read existing logs
            logs = []
            if os.path.exists(self.log_file):
                try:
                    with open(self.log_file, 'r') as f:
                        logs = json.load(f)
                except (json.JSONDecodeError, IOError):
                    logs = []
            
            # Add new entry
            logs.append(entry)
            
            # Keep only recent entries
            if len(logs) > self.max_history:
                logs = logs[-self.max_history:]
            
            # Write back to file
            with open(self.log_file, 'w') as f:
                json.dump(logs, f, indent=2, default=str)
                
        except Exception as e:
            self.logger.error(f"File save error: {e}")

    def display_stats(self):
        """Display performance statistics"""
        while self.monitoring:
            try:
                self.print_stats()
                time.sleep(15)  # Update every 15 seconds
            except Exception as e:
                self.logger.error(f"Stats display error: {e}")
                time.sleep(15)

    def print_stats(self):
        """Print current performance statistics"""
        try:
            process = psutil.Process()
            uptime = time.time() - self.stats['process']['create_time']
            uptime_str = str(timedelta(seconds=int(uptime)))
            
            cpu_usage = self.stats['cpu']['usage']
            memory_percent = self.stats['memory']['percent']
            process_memory = self.stats['process']['memory_info'].get('rss', 0) / 1024 / 1024  # MB
            
            print(f"""
🐍 PYTHON PERFORMANCE MONITOR 🐍
Uptime: {uptime_str}
CPU Usage: {cpu_usage:.1f}% ({self.stats['cpu']['cores']} cores)
Memory Usage: {memory_percent:.1f}%
Process Memory: {process_memory:.1f}MB
Process CPU: {self.stats['process']['cpu_percent']:.1f}%
Threads: {self.stats['process']['num_threads']}
Network Connections: {self.stats['network']['connections']}
History Entries: {len(self.history)}
════════════════════════════════════
""")
            
        except Exception as e:
            self.logger.error(f"Stats printing error: {e}")

    def get_system_info(self) -> Dict[str, Any]:
        """Get comprehensive system information"""
        try:
            return {
                'platform': {
                    'system': psutil.WINDOWS if sys.platform == 'win32' else psutil.LINUX,
                    'platform': sys.platform,
                    'python_version': sys.version,
                    'boot_time': psutil.boot_time()
                },
                'cpu': {
                    'physical_cores': psutil.cpu_count(logical=False),
                    'logical_cores': psutil.cpu_count(logical=True),
                    'max_frequency': psutil.cpu_freq().max if psutil.cpu_freq() else None,
                    'min_frequency': psutil.cpu_freq().min if psutil.cpu_freq() else None
                },
                'memory': {
                    'total_gb': round(psutil.virtual_memory().total / (1024**3), 2),
                    'swap_total_gb': round(psutil.swap_memory().total / (1024**3), 2)
                },
                'disk': {
                    'partitions': len(psutil.disk_partitions()),
                    'total_size': sum(
                        psutil.disk_usage(p.mountpoint).total 
                        for p in psutil.disk_partitions() 
                        if os.path.exists(p.mountpoint)
                    )
                }
            }
        except Exception as e:
            self.logger.error(f"System info error: {e}")
            return {}

    def get_performance_report(self) -> Dict[str, Any]:
        """Generate comprehensive performance report"""
        try:
            report = {
                'timestamp': datetime.now().isoformat(),
                'system_info': self.get_system_info(),
                'current_stats': self.stats.copy(),
                'history_summary': {
                    'entries': len(self.history),
                    'time_range': {
                        'start': self.history[0]['timestamp'] if self.history else None,
                        'end': self.history[-1]['timestamp'] if self.history else None
                    }
                },
                'alerts': self.check_alerts()
            }
            return report
        except Exception as e:
            self.logger.error(f"Performance report error: {e}")
            return {}

    def check_alerts(self) -> List[Dict[str, Any]]:
        """Check for performance alerts"""
        alerts = []
        
        try:
            # CPU alert
            if self.stats['cpu']['usage'] > 90:
                alerts.append({
                    'type': 'cpu',
                    'severity': 'critical',
                    'message': f"High CPU usage: {self.stats['cpu']['usage']:.1f}%",
                    'timestamp': datetime.now().isoformat()
                })
            
            # Memory alert
            if self.stats['memory']['percent'] > 90:
                alerts.append({
                    'type': 'memory',
                    'severity': 'critical',
                    'message': f"High memory usage: {self.stats['memory']['percent']:.1f}%",
                    'timestamp': datetime.now().isoformat()
                })
            
            # Disk alert
            for device, usage in self.stats['disk']['usage'].items():
                if usage['percent'] > 90:
                    alerts.append({
                        'type': 'disk',
                        'severity': 'warning',
                        'message': f"High disk usage on {device}: {usage['percent']:.1f}%",
                        'timestamp': datetime.now().isoformat()
                    })
            
        except Exception as e:
            self.logger.error(f"Alert checking error: {e}")
        
        return alerts

    def stop_monitoring(self):
        """Stop all monitoring threads"""
        self.monitoring = False
        self.logger.info("🛑 Stopping performance monitoring...")
        
        # Wait for threads to finish
        for thread in self.threads:
            if thread.is_alive():
                thread.join(timeout=5)
        
        self.logger.info("✅ Performance monitoring stopped")

def main():
    """Main function"""
    monitor = PerformaMonitorPython()
    
    try:
        monitor.start_monitoring()
        
        # Keep the main thread alive
        while monitor.monitoring:
            time.sleep(1)
            
    except KeyboardInterrupt:
        monitor.logger.info("Received keyboard interrupt")
    except Exception as e:
        monitor.logger.error(f"Main loop error: {e}")
    finally:
        monitor.stop_monitoring()

if __name__ == '__main__':
    main()
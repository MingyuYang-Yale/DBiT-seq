import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('PDF')
import NaiveDE
import SpatialDE
import sys

def get_coords(index):
    coords = pd.DataFrame(index=index)
    coords['x'] = index.str.split('x').str.get(0).map(float)
    coords['y'] = index.str.split('x').str.get(1).map(float)
    return coords

def main():
    df = pd.read_csv('10t.csv', index_col=0)  
    df = df.T[df.sum(0) >= 3].T
    sample_info = get_coords(df.index)
    sample_info['total_counts'] = df.sum(1) 
    sample_info = sample_info.query('total_counts > 10')  # Remove empty features  
    df = df.loc[sample_info.index] 
   # X = sample_info[['x', 'y']] 
    dfm = NaiveDE.stabilize(df.T).T
    res = NaiveDE.regress_out(sample_info, dfm.T, 'np.log(total_counts)').T 
    res['log_total_count'] = np.log(sample_info['total_counts']) 
    results=pd.read_csv('10t_final_results.csv', index_col=0) 

    results['pval'] = results['pval'].clip_lower(results.query('pval > 0')['pval'].min() / 2)
    results['qval'] = results['qval'].clip_lower(results.query('qval > 0')['qval'].min() / 2)
    ymy = int(sys.argv[1])
    sres = results.query('qval < 0.05 & g != "log_total_count"').copy()
    #a = sres['l'].value_counts()
    #a.to_csv('10t_l_results.csv')
    X = sample_info[['x', 'y']].values
    histology_results, patterns = SpatialDE.spatial_patterns(X, res, sres, ymy, 11, verbosity=1)
    histology_results.to_csv('10t_AEH_results.{}.csv'.format(ymy))
    patterns.add_prefix('pattern_').to_csv('10t_pattern_results.{}.csv'.format(ymy))
    for i, Ci in enumerate(histology_results.sort_values('pattern').pattern.unique()):
        fig = plt.figure(figsize=(5, 5))
        plt.scatter(sample_info['x'], sample_info['y'], c=patterns[Ci] ,s=10,  cmap=plt.get_cmap("YlOrBr"), edgecolor="none", marker='s')
        plt.axis([0, 50, 0, 50]) 
        plt.xlim(0, 50) 
        plt.ylim(0, 50) 
        plt.xticks([0,10,20,30,40,50])
        plt.yticks([0,10,20,30,40,50])
        plt.axis('equal') 
        plt.gca().invert_yaxis() 
        plt.title('Pattern {} - {} genes'.format(i, histology_results.query('pattern == @i').shape[0] ),size=20)
        plt.tight_layout() 
        plt.savefig("10t.{}.{}.pdf".format(ymy, i), bbox_inches='tight')
    for i in histology_results.sort_values('pattern').pattern.unique():
        print('Pattern {}'.format(i))
        print(', '.join(histology_results.query('pattern == @i').sort_values('membership')['g'].tolist()))
        print()

    return histology_results


if __name__ == '__main__':
    histology_results = main()

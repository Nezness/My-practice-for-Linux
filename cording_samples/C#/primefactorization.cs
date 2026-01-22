using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace Prime
{
    class PrimeFactorization
    {
        static void Main(string[] args)
        {
            while(true)
            {
            Console.Write("素因数分解したい3以上の自然数を入力してください(19桁まで):");
            ulong a = ulong.Parse(Console.ReadLine());
            ulong b = a;
            ulong[] factors = {0};

            for(int i = 1 ;; i++)    
            {
                ulong c = 2;
                if(a <= 1) //aが1以下の場合
                {
                    Console.WriteLine("2以上の正の整数を入力してください。");
                    break;
                }
                else if(a == 2) //aが2の場合
                {
                    Console.WriteLine("{0}は素数", a);
                    break;
                }
                else if(b % 2 == 0) //bが偶数の場合
                {
                    b = b / 2;
                    Array.Resize(ref factors, factors.Length + 1);
                    factors[i - 1] = 2;
                }
                else if(b == 1) //bが1の場合
                {
                    break;
                }
                else if(!(b % 2 == 0)) //bが奇数の場合
                {
                    while(true)
                    {
                        ulong d = b % c;
                        ulong e = c * c;    
                    
                        if((c == b - 1)|(e > b))
                        {
                            Array.Resize(ref factors, factors.Length + 1);
                            factors[i-1] = b;
                            b = 1;
                            break;
                        }
                        else if(!(d == 0))
                        {
                            c = c + 1; 
                        }                       
                        else if(d == 0) //aが正の奇数を約数に持つ場合
                        {
                            b = b / c;
                            Array.Resize(ref factors, factors.Length + 1);
                            factors[i-1] = c;
                            i = i + 1;
                        }
                    }
                 }
            }
            
            Console.Write("{0} = ", a);
            int f = factors.Length;
            for(int j = 1; j < f; j++)
            {
                if(j == f - 1)
                {
                    Console.Write("{0}", factors[j-1]);
                }
                else if(j < f && !(j == f - 1))
                {
                    Console.Write("{0} * ", factors[j-1]);
                }
            }
            Console.WriteLine();
            Console.Write("続ける場合はEnterを入力してください。");
            Console.ReadLine();
            }
        }
    }
}
